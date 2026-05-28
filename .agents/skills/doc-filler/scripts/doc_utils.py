#!/usr/bin/env python3
"""
doc-filler 辅助工具
Word 文档读取、占位符检测、填充、验证
"""

import sys
import os
import json
import re
from docx import Document
from docx.shared import Pt, RGBColor, Inches
from docx.oxml.ns import qn
from copy import deepcopy

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def _run_with_venv():
    """确保在 venv 环境下运行"""
    venv_python = os.path.join(REPO, "venv", "bin", "python3")
    if sys.executable != venv_python and os.path.exists(venv_python):
        os.execv(venv_python, [venv_python] + sys.argv)


# ============================================================
# 1. 读取文档内容
# ============================================================

def read_docx(path):
    """读取 .docx 文件，返回结构化文本"""
    doc = Document(path)
    lines = []
    for para in doc.paragraphs:
        lines.append({
            "type": "paragraph",
            "style": para.style.name if para.style else None,
            "text": para.text,
        })
    for i, table in enumerate(doc.tables):
        rows = []
        for row in table.rows:
            cells = [cell.text.strip() for cell in row.cells]
            rows.append(cells)
        lines.append({
            "type": "table",
            "index": i,
            "rows": rows,
        })
    return lines


def docx_to_text(path):
    """读取 .docx 并转为纯文本"""
    doc = Document(path)
    parts = []
    for para in doc.paragraphs:
        parts.append(para.text)
    for table in doc.tables:
        for row in table.rows:
            parts.append(" | ".join(cell.text.strip() for cell in row.cells))
    return "\n".join(parts)


# ============================================================
# 2. 检测占位符
# ============================================================

PLACEHOLDER_PATTERNS = [
    r"\{\{(.+?)\}\}",       # {{field_name}}
    r"\[(.+?)\]",            # [field_name]
    r"__([A-Z_\d]+?)__",    # __FIELD_NAME__
    r"＜(.+?)＞",            # 中文全角尖括号
    r"《(.+?)》",            # 中文书名号
]

PLACEHOLDER_MARKERS = [
    "{{", "}}", "[", "]", "__", "＜", "＞", "《", "》"
]

def find_placeholders(path):
    """扫描文档中所有占位符并返回"""
    doc = Document(path)
    found = {"paragraphs": [], "tables": []}
    seen = set()

    for pi, para in enumerate(doc.paragraphs):
        for pat in PLACEHOLDER_PATTERNS:
            for m in re.finditer(pat, para.text):
                key = m.group(1).strip()
                if key and key not in seen:
                    seen.add(key)
                    found["paragraphs"].append({
                        "key": key,
                        "match": m.group(0),
                        "paragraph_index": pi,
                        "sample": _context(para.text, m.start(), m.end()),
                    })

    for ti, table in enumerate(doc.tables):
        for ri, row in enumerate(table.rows):
            for ci, cell in enumerate(row.cells):
                for pat in PLACEHOLDER_PATTERNS:
                    for m in re.finditer(pat, cell.text):
                        key = m.group(1).strip()
                        if key and key not in seen:
                            seen.add(key)
                            found["tables"].append({
                                "key": key,
                                "match": m.group(0),
                                "table_index": ti,
                                "row": ri,
                                "col": ci,
                                "header": (table.rows[0].cells[ci].text.strip()
                                           if table.rows and ri > 0 else ""),
                            })

    return found


def _context(text, start, end, width=20):
    """返回占位符附近上下文"""
    left = text[max(0, start - width):start]
    right = text[end:end + width]
    return f"...{left}[{text[start:end]}]{right}..."


# ============================================================
# 3. 填充文档（处理 Word 跨 run 分割）
# ============================================================

def fill_docx(template_path, output_path, field_map, highlight=True):
    """
    将 field_map 中的值填入模板文档
    field_map: {"field_key": "value"}
    highlight=True: 填充内容加下划线，便于检查
    """
    doc = Document(template_path)

    # 构建所有占位符 → 值的映射
    replace_map = {}
    for key, value in field_map.items():
        if not value:
            continue
        for bracket_left, bracket_right in [("{{", "}}"), ("[", "]"),
                                              ("__", "__"), ("＜", "＞"),
                                              ("《", "》")]:
            replace_map[bracket_left + key + bracket_right] = str(value)

    # 段落填充
    for para in doc.paragraphs:
        _replace_in_para(para, replace_map, highlight)

    # 表格填充（遍历 cell 内的段落）
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for para in cell.paragraphs:
                    _replace_in_para(para, replace_map, highlight)

    doc.save(output_path)
    return output_path


def _replace_in_para(para, replace_map, highlight):
    """
    在段落中安全替换占位符。
    Word 可能把 {{字段}} 拆成多个 run。
    策略：合并全文 → 替换 → 写回第一个 run，清空其余 run 的文本。
    """
    full = para.text
    marker_found = any(m in full for m in PLACEHOLDER_MARKERS)
    if not marker_found:
        return

    changed = False
    for old, new in replace_map.items():
        if old in full:
            full = full.replace(old, new, 1)
            changed = True

    if not changed:
        return

    if para.runs:
        para.runs[0].text = full
        if highlight:
            para.runs[0].underline = True
        for r in para.runs[1:]:
            r.text = ""
    else:
        run = para.add_run(full)
        if highlight:
            run.underline = True


# ============================================================
# 4. 验证完整性
# ============================================================

def verify_fill(result_path):
    """检查填充后文档是否还有未替换的占位符"""
    doc = Document(result_path)
    unfilled = []

    for pi, para in enumerate(doc.paragraphs):
        for pat in PLACEHOLDER_PATTERNS:
            for m in re.finditer(pat, para.text):
                unfilled.append({
                    "key": m.group(1).strip(),
                    "location": f"段落 {pi}",
                    "match": m.group(0),
                })

    for ti, table in enumerate(doc.tables):
        for ri, row in enumerate(table.rows):
            for ci, cell in enumerate(row.cells):
                for pat in PLACEHOLDER_PATTERNS:
                    for m in re.finditer(pat, cell.text):
                        unfilled.append({
                            "key": m.group(1).strip(),
                            "location": f"表格 {ti} 第 {ri} 行 第 {ci} 列",
                            "match": m.group(0),
                        })

    return unfilled


# ============================================================
# 5. 智能字段匹配（辅助 AI 理解）
# ============================================================

def smart_match(source_text, target_placeholders, context_hints=None):
    """
    根据源文本内容和占位符名称推荐填充映射。
    context_hints: 可选的额外上下文（如表头、附近文字）
    """
    mapping = {}
    for ph in target_placeholders:
        key = ph["key"]
        value = _extract_field(source_text, key, context_hints)
        if value:
            mapping[key] = value
    return mapping


def _extract_field(text, field_name, context_hints=None):
    """从文本中提取某个字段的值（启发式）"""
    # 1. 字段名在行首/冒号后的值
    patterns = [
        # "字段名：值" 或 "字段名: 值"
        rf"{re.escape(field_name)}\s*[：:]\s*([^\n\r;；，,、。\.]+?)(?:\s*[\n\r]|$)",
        # "字段名称：" 后跟的值
        rf"{re.escape(field_name)}名称?\s*[：:]\s*([^\n\r;；，,、。\.]+?)(?:\s*[\n\r]|$)",
        # 字段名在行尾，下一行是值（少见）
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            val = m.group(1).strip()
            if val and len(val) < 200:
                return val

    # 2. 尝试部分匹配（字段名中的关键词）
    # 去掉可能的"名称""编号""金额"等后缀
    short_key = re.sub(r'(名称|编号|号码|金额|数字|日期)$', '', field_name)
    if short_key != field_name and len(short_key) >= 2:
        return _extract_field(text, short_key)

    return ""


# ============================================================
# CLI 入口
# ============================================================

def main():
    if len(sys.argv) < 2:
        print("用法:")
        print("  python doc_utils.py read <path.docx>          # 读取文档")
        print("  python doc_utils.py scan <path.docx>          # 扫描占位符")
        print("  python doc_utils.py fill <template.docx> <out.docx> <mapping.json>  # 填充")
        print("  python doc_utils.py verify <path.docx>        # 验证填充")
        print("  python doc_utils.py match <source.txt> <target.docx>  # 智能匹配")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "read":
        content = read_docx(sys.argv[2])
        print(json.dumps(content, ensure_ascii=False, indent=2))

    elif cmd == "scan":
        placeholders = find_placeholders(sys.argv[2])
        print(json.dumps(placeholders, ensure_ascii=False, indent=2))

    elif cmd == "fill":
        if len(sys.argv) < 5:
            print("需要: template.docx out.docx mapping.json")
            sys.exit(1)
        with open(sys.argv[4]) as f:
            mapping = json.load(f)
        out = fill_docx(sys.argv[2], sys.argv[3], mapping)
        print(json.dumps({"output": out, "status": "ok"}))

    elif cmd == "verify":
        unfilled = verify_fill(sys.argv[2])
        if unfilled:
            print(json.dumps({"status": "incomplete", "unfilled": unfilled},
                             ensure_ascii=False, indent=2))
        else:
            print(json.dumps({"status": "complete", "message": "所有占位符已填充"}))

    elif cmd == "match":
        if len(sys.argv) < 4:
            print("需要: source.txt target.docx")
            sys.exit(1)
        with open(sys.argv[2]) as f:
            source = f.read()
        ph = find_placeholders(sys.argv[3])
        all_keys = ph["paragraphs"] + ph["tables"]
        mapping = smart_match(source, all_keys)
        print(json.dumps(mapping, ensure_ascii=False, indent=2))

    else:
        print(f"未知命令: {cmd}")


if __name__ == "__main__":
    _run_with_venv()
    main()