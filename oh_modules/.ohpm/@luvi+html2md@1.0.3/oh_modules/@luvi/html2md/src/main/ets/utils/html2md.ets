export function html2md(src: string) {
  let html = src
  const tagFlag = "XbPPhQBQyq/7srSx0f5ZXA==" // base64 "html2md_luvi_tag_flag"
  const whiteListFlag = "3CocpfgWp5bWKribiWUeDw==" // base64 "html2md_luvi_white_list_flag"
  let html2mdResult = ""

  // 处理白名单
  const writeListRegex = /```([\s\S]*?)```/g;
  let match: string[] | null = [];
  let whiteListResult: string[] = [];
  while ((match = writeListRegex.exec(html)) !== null) {
    whiteListResult.push(match[0].trim());
  }
  html = html.replace(writeListRegex, whiteListFlag)

  // replace span
  html = html.replace(/<\s*span[^>]*>\s*(.*?)\s*<\s*\/\s*span>/gi, '$1');
  // replace text
  html = html.replace(/<\s*text[^>]*>\s*(.*?)\s*<\s*\/\s*text>/gi, '$1');
  // replace text
  html = html.replace(/<\s*mark[^>]*>\s*(.*?)\s*<\s*\/\s*mark>/gi, '==$1==');
  // replace hr
  html = html.replace(/<\s*hr[^>]*>/gi, '\n---\n');
  // replace br
  html = html.replace(/<\s*br[^>]*>/gi, '\n');

  // replace b
  html = html.replace(/<\s*b[^>]*>\s*(.*?)\s*<\s*\/\s*b>/gi, '**$1**');
  // replace strong
  html = html.replace(/<\s*strong[^>]*>\s*(.*?)\s*<\s*\/\s*strong>/gi, '**$1**');
  // replace 斜体标签
  html = html.replace(/<\s*i[^>]*>\s*(.*?)\s*<\s*\/\s*i>/gi, '_$1_');
  // replace dfn
  html = html.replace(/<\s*dfn[^>]*>\s*(.*?)\s*<\s*\/\s*dfn>/gi, '_$1_');
  // replace em
  html = html.replace(/<\s*em[^>]*>\s*(.*?)\s*<\s*\/\s*em>/gi, '_$1_');
  // replace u
  html = html.replace(/<\s*u[^>]*>\s*(.*?)\s*<\s*\/\s*u>/gi, '__$1__');
  // replace del
  html = html.replace(/<\s*del[^>]*>\s*(.*?)\s*<\s*\/\s*del>/gi, '~~$1~~');
  // replace blockquote
  html = html.replace(/<\s*blockquote[^>]*>\s*(.*?)\s*<\s*\/\s*blockquote>/gi, '> $1');
  // replace code
  html = html.replace(/<\s*code[^>]*>\s*(.*?)\s*<\s*\/\s*code>/gi, '`$1`');

  // replace title
  for (let i = 1; i <= 6; i++) {
    const tag = `<h${i}>`;
    const endTag = `</h${i}>`;
    const replacement = '#'.repeat(i) + ' ';
    const regex = new RegExp(tag + '([^<]+)' + endTag, 'gi');
    html = html.replace(regex, replacement + '$1');
  }

  // replace div
  // html = html.replace(/<*div[^>]*>\s*([\s\S]*?)\s*<*\/\s*div>/gi, '$1');
  html = html.replace(/<div[^>]*>/gi, '');
  html = html.replace(/<\/*div[^>]*>/gi, '');
  // replace p
  html = html.replace(/<\s*p[^>]*>\s*([\s\S]*?)\s*<\s*\/\s*p>/gi, '\n$1\n');
  // replace pre
  html = html.replace(/<\s*pre[^>]*>\s*([\s\S]*?)\s*<\s*\/\s*pre>/gi, '$1');
  // replace a
  html = html.replace(/<\s*a\s+[^>]*href="([^"]+)"[^>]*>\s*(.*?)\s*<\s*\/\s*a>/gi, '[$2]($1)');
  // replace img
  html = html.replace(/<\s*img.+?src="([^"]+)"[^>]*?alt="([^"]+)"[^>]*?>/gi, '![$2]($1)');
  html = html.replace(/<\s*img.+?alt="([^"]+)"[^>]*?src="([^"]+)"[^>]*?>/gi, '![$2]($1)');
  html = html.replace(/<\s*img.*?src="([^"]+)"[^>]*>/gi, '![$1]()');
  // replace video
  // html = html.replace(/<\s*video src="([^"]+)"[^>]*>/gi, '![]($1)');

  const ulRegex = /<ul>[\s\S]*?<\/ul>/g;
  const olRegex = /<ol>[\s\S]*?<\/ol>/g;
  const liRegex = /<li>\s*(.*?)\s*<\/li>/g;

  // ul li
  html = html.replace(ulRegex, (match: string) => {
    const items = match.match(liRegex);
    if (!items) {
      return match;
    }
    return items.map((item) => `- ${item.slice(4, -5)}`).join('\n');
  });

  // ol li
  html = html.replace(olRegex, (match: string) => {
    const items = match.match(liRegex);
    if (!items) {
      return match;
    }
    return items.map((item, index) => `${index + 1}. ${item.slice(4, -5)}`).join('\n');
  });

  // remove ol ul
  html = html.replace(/<\/?ul>|<\/?ol>/g, '');

  let htmlSplit: string[] = html.split("\n")
    .map((item: string) => item.trim());

  let flag = true
  // tagFlagRegex处理特殊标签取出后留下的空行
  let tagFlagRegex = new RegExp(tagFlag, "gi")
  let whiteNum = 0
  htmlSplit.forEach(element => {
    if (element == whiteListFlag) {
      element = whiteListResult[whiteNum]
      whiteNum++
    }

    if (element && flag && element !== tagFlag) {
      flag = false
      html2mdResult += element + "\n"
    } else {
      // 不能判断等于 字符串空 ，会丢失换行
      if (!flag && element != undefined && element != null && element !== tagFlag) {
        html2mdResult += element.replace(tagFlagRegex, "") + "\n"
      }
    }
  });

  return html2mdResult;
}