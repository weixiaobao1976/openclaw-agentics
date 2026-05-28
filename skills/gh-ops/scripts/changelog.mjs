#!/usr/bin/env node
/**
 * 生成版本间 CHANGELOG (基于 PR)
 * 用法: node scripts/changelog.mjs owner/repo --from v1.0.0 --to v1.1.0
 */

import { execSync } from 'child_process';

const [repo] = process.argv.slice(2).filter(a => !a.startsWith('--') && !a.startsWith('v'));
let fromTag, toTag;
const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--from') fromTag = args[++i];
  if (args[i] === '--to') toTag = args[++i];
}

try {
  const toTagRef = toTag || 'HEAD';

  // 用 gh API 查合并的 PR 生成 changelog
  console.log(`\n📝 CHANGELOG: ${repo} ${fromTag ? fromTag + ' → ' + toTagRef : '最近7天'}\n`);

  const prs = JSON.parse(execSync(
    `gh pr list --repo ${repo} --state merged --limit 30 --json number,title,mergedAt,labels,author`,
    { encoding: 'utf-8', timeout: 15000 }
  ));

  if (prs.length === 0) {
    console.log('暂无合并的 PR。');
    process.exit(0);
  }

  console.log(`### 已合并 PR (${prs.length} 个)\n`);
  for (const pr of prs) {
    const labels = pr.labels.map(l => `\`${l.name}\``).join(' ') || '';
    const date = pr.mergedAt.slice(0, 10);
    console.log(`- **#${pr.number}** ${pr.title} — @${pr.author.login} (${date}) ${labels}`);
  }
  console.log();

} catch (err) {
  console.error('❌ 获取失败:', err.message);
  process.exit(1);
}