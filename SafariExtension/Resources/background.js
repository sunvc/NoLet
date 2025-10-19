
// 创建菜单的函数
function createContextMenu() {
    const contexts = ["page", "selection", "link", "image", "video", "audio"];
    const contextDic = {
        page: chrome.i18n.getMessage("pageLocal"),
        selection: chrome.i18n.getMessage("selectionLocal"),
        link: chrome.i18n.getMessage("linkLocal"),
        image: chrome.i18n.getMessage("imageLocal"),
        video: chrome.i18n.getMessage("videoLocal"),
        audio: chrome.i18n.getMessage("audioLocal"),
    };

    for (let i = 0; i < contexts.length; i++) {
        const context = contexts[i];
        const title = chrome.i18n.getMessage("sendAnyToIphoneLocal", [contextDic[context]]);
        chrome.contextMenus.create({
            title: title,
            contexts: [context],
            id: context,
        });
    }
}




// 处理右键菜单点击事件
function genericOnClick(info) {
    var result = "";
    switch (info.menuItemId) {
    case "image":
        result = info.srcUrl;
        break;
    case "video":
        result = info.srcUrl;
        break
    case "selection":
        result = info.selectionText;
        break;
    case "link":
        result = info.linkUrl;
        break;
    default:
        return
    }
    console.log("点击结束", info)
    sendToPhone(result, info.menuItemId);
}

function sendToPhone(data, mode) {
    chrome.storage.sync.get("config", (result) => {
        let keys = result.config.keys || [];
        if (!keys || keys.length === 0) {
            return;
        }
        let sound = result.config.sound || "success";
        let group = result.config.group || "Safari";
        let level = result.config.level || "active";

        let params = {
            sound: sound,
            group: group,
            level: level,
            title: chrome.i18n.getMessage("browserDataLocal"),
            body: mode,
            icon: "https://developer.apple.com/assets/elements/icons/safari-macos-11/safari-macos-11-96x96_2x.png",
        };
        // "page", "selection", "link", "image", "video", "audio"
        if (mode === "page" || mode === "link" || mode === "audio") {
            params.url = data;
        } else if (mode === "image") {
            params.image = data;
        } else if (mode === "video") {
            params.video = data;
        } else {
            params.body = data;
        }

        keys.forEach((key) => {
            makeRequest(key, params);
        });
    });
}


// 编写一个请求函数，使用 encodeURIComponent 对参数进行编码
function makeRequest(key, params) {
    // 优先使用 CORS + JSON 发送
    const jsonBody = JSON.stringify(params);
    fetch(key, {
        method: "POST",
        mode: "cors",
        headers: {
            "Content-Type": "application/json",
        },
        body: jsonBody,
    })
    .then((resp) => {
        console.log("CORS JSON response status:", resp.status);
        // 尝试读取文本以便排查（若服务端允许）
        return resp.text().then((t) => console.log("CORS JSON response body:", t)).catch(() => {});
    })
    .catch(console.log);
}

// 创建右键菜单
createContextMenu();


// 通用的点击处理函数
chrome.contextMenus.onClicked.addListener(genericOnClick);



