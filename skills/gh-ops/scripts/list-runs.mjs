#!/usr/bin/env node
import { execSync } from 'child_process';
const [repo] = process.argv.slice(2).filter(a => !a.startsWith('--'));
const days = parseInt(process.argv[process.argv.indexOf('--days')+1]) || 7;
const limit = parseInt(process.argv[process.argv.indexOf('--limit')+1]) || 20;
const raw = execSync(`gh run list --repo ${repo} --limit ${limit} --json databaseId,displayTitle,workflowName,status,conclusion,createdAt,headBranch`, {encoding:'utf-8',timeout:15000});
const runs = JSON.parse(raw);
console.log(`\n📋 ${repo} — 最近 ${days} 天 (${runs.length} 个)\n`);
console.log(`${'状态'.padEnd(10)} ${'结论'.padEnd(10)} ${'日期'.padEnd(20)} ${'分支'.padEnd(20)} ${'Workflow'}`);
for (const r of runs) {
  const s = r.status==='completed'?'✅':'⏳';
  const c = r.conclusion ? r.conclusion.padEnd(10) : '运行中...';
  const d = r.createdAt.slice(0,16).replace('T',' ');
  console.log(`${s.padEnd(10)} ${c} ${d.padEnd(20)} ${r.headBranch.padEnd(20)} ${r.workflowName}`);
}
