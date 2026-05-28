#!/usr/bin/env node
/**
 * 列出仓库最近 workflow runs
 * 用法: node scripts/list-runs.mjs owner/repo --days 7 --limit 20
 */

import { execSync } from 'child_process';

const [repo] = process.argv.slice(2).filter(a => !a.startsWith('--'));
const days = parseInt(process.argv[process.argv.indexOf('--days') + 1]) || 7;
const limit = parseInt(process.argv[process.argv.indexOf('--limit') + 1]) || 20;

const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

try {
  const raw = execSync(`gh run list --repo ${repo} --limit ${limit} --json databaseId,displayTitle,workflowName,status,conclusion,createdAt,headBranch`, {
    encoding: 'utf-8', timeout: 15000
  });
  const runs = JSON.parse(raw);

  console.log(`\n📋 ${repo} — 最近 ${days} 天 Workflow Runs (显示 ${runs.length} 个)\n`);
  console.log(`${'状态'.padEnd(10)} ${'结论'.padEnd(10)} ${'日期'.padEnd(20)} ${'分支'.padEnd(20)} ${'Workflow'}`);
  console.log('-'.repeat(80));

  for (const r of runs) {
    const status = r.status === 'completed' ? '✅' : '⏳';
    const conclusion = r.conclusion ? r.conclusion.padEnd(10) : '运行中...';
    const date = r.createdAt.slice(0, 16).replace('T', ' ');
    console.log(`${status.padEnd(10)} ${conclusion} ${date.padEnd(20)} ${r.headBranch.padEnd(20)} ${r.workflowName}`);
  }
  console.log();
} catch (err) {
  console.error('❌ 获取失败:', err.message);
  process.exit(1);
}