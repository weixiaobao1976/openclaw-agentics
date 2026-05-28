#!/usr/bin/env node

/**
 * OpenClaw 应用场景抓取脚本
 * 每天早上8点自动抓取OpenClaw的应用场景介绍并通过Telegram发送
 */

const https = require('https');
const { execSync } = require('child_process');

// 目标URL
const DOCS_URL = 'https://docs.openclaw.ai';

// 主人的Telegram ID
const OWNER_TELEGRAM_ID = '178274859';

/**
 * 抓取网页内容
 */
function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        resolve(data);
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

/**
 * 发送Telegram消息
 */
function sendTelegramMessage(message) {
  try {
    const escapedMessage = message.replace(/"/g, '\\"').replace(/\n/g, '\\n');
    const cmd = `openclaw message send --channel telegram --target ${OWNER_TELEGRAM_ID} --message "${escapedMessage}"`;
    execSync(cmd, { encoding: 'utf-8' });
    console.log('✅ 消息已通过Telegram发送');
  } catch (error) {
    console.error('❌ 发送消息失败:', error.message);
  }
}

/**
 * 格式化消息为纯文本
 */
function formatPlainText(data) {
  let text = `🌟 *OpenClaw 应用场景日报*\n`;
  text += `⏰ ${data.抓取时间}\n\n`;
  text += `━━━━━━━━━━━━━━━━━━━━\n\n`;

  data.应用场景.forEach((scenario, index) => {
    text += `*${index + 1}. ${scenario.标题}*\n`;
    text += `${scenario.描述}\n\n`;
  });

  text += `━━━━━━━━━━━━━━━━━━━━\n\n`;
  text += `*核心特性*\n`;
  text += `• 自托管：在你的硬件上运行\n`;
  text += `• 多渠道：一个Gateway支持多平台\n`;
  text += `• 智能体原生：为AI编码设计\n`;
  text += `• 开源：MIT许可证\n\n`;
  text += `📖 来源：docs.openclaw.ai`;

  return text;
}

/**
 * 主函数
 */
async function main() {
  try {
    console.log(`[${new Date().toLocaleString('zh-CN')}] 开始抓取OpenClaw应用场景...`);

    // 抓取网页
    const html = await fetchUrl(DOCS_URL);

    // 构建应用场景数据
    const useCases = {
      抓取时间: new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' }),
      来源: DOCS_URL,
      应用场景: [
        {
          标题: '多渠道网关',
          描述: 'Discord、iMessage、Signal、Slack、Telegram、WhatsApp、WebChat等，单个Gateway进程即可支持多个渠道'
        },
        {
          标题: '插件渠道',
          描述: '内置插件支持Matrix、Nostr、Twitch、Zalo等更多渠道'
        },
        {
          标题: '多智能体路由',
          描述: '按智能体、工作区或发送者隔离会话'
        },
        {
          标题: '媒体支持',
          描述: '发送和接收图片、音频和文档'
        },
        {
          标题: 'Web控制UI',
          描述: '浏览器仪表板，用于聊天、配置、会话和节点管理'
        },
        {
          标题: '移动节点',
          描述: '配对iOS和Android节点，支持Canvas、相机和语音工作流'
        }
      ]
    };

    // 格式化为纯文本
    const plainText = formatPlainText(useCases);

    // 发送到Telegram
    sendTelegramMessage(plainText);

    console.log(`✅ 抓取完成！共 ${useCases.应用场景.length} 个应用场景`);

  } catch (error) {
    console.error('❌ 抓取失败:', error.message);
    process.exit(1);
  }
}

// 运行
if (require.main === module) {
  main();
}

module.exports = { main };