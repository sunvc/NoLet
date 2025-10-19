document.addEventListener("DOMContentLoaded", () => {
    // Load saved options and set up initial state
    loadOptions();
    setLang();
});

function loadOptions() {
    browser.storage.sync.get("config", function (result) {
        let keyList = document.getElementById("key-list");
        let keyResult = result.config.keys || [];

        keyResult.forEach((keyValue, index) => {
            const listItem = document.createElement("li");
            listItem.textContent = keyValue;

            const removeBtn = document.createElement("button");
            removeBtn.type = "button";
            removeBtn.textContent = "x";
            removeBtn.className = "removeBtn";
            removeBtn.addEventListener("click", () => {
                keyList.removeChild(listItem);
                saveConfig();
            });

            listItem.appendChild(removeBtn);
            keyList.appendChild(listItem);
        });

        // 处理获取到的 result
        console.log(result);
        document.getElementById("sound").value = result.config.sound || "success";
        document.getElementById("group").value = result.config.group || "Safari";
        document.getElementById("level").value = result.config.level || "active";
    });
}

document.getElementById("add-key").addEventListener("click", () => {
    const keyInput = document.getElementById("key-input");
    const keyList = document.getElementById("key-list");
    const keyValue = keyInput.value.trim();

    // 检查输入是否为空
    if (!keyValue) {
        message("Invalid key");
        return;
    }

    // 检查是否为有效的 URL
    const urlPattern = /^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/[\w\-._~:/?#[\]@!$&'()*+,;=]*)?$/;
    if (!urlPattern.test(keyValue)) {
        message("Key must be a valid URL");
        return;
    }

    // 检查是否重复
    const existingKeys = Array.from(keyList.children).map((li) => li.firstChild.textContent);
    if (existingKeys.includes(keyValue)) {
        message("Key repeat");
        return;
    }

    // 添加到列表
    const listItem = document.createElement("li");
    listItem.textContent = keyValue;

    const removeBtn = document.createElement("button");
    removeBtn.type = "button";
    removeBtn.textContent = "X";
    removeBtn.addEventListener("click", () => {
        keyList.removeChild(listItem);
    });
    removeBtn.className = "removeBtn";
    listItem.appendChild(removeBtn);
    keyList.appendChild(listItem);
    saveConfig();
    // 清空输入框
    keyInput.value = "";
});

document.getElementById("sound").addEventListener("input", (e) => {
    console.log("Sound changed to:", e.target.value);
    saveConfig();
});

document.getElementById("group").addEventListener("input", (e) => {
    console.log("group changed to:", e.target.value);
    saveConfig();
});

document.getElementById("level").addEventListener("change", function (e) {
    const selectedValue = e.target.value;
    console.log("Level changed to:", selectedValue);
    saveConfig()
});


function saveConfig(){
    const keys = Array.from(document.getElementById("key-list").children).map((li) => li.firstChild.textContent);
    const config = {
        keys: keys,
        sound: document.getElementById("sound").value,
        group: document.getElementById("group").value,
        level: document.getElementById("level").value,
    };
    browser.storage.sync.set({ config: config });
}

function message(msg) {
    const popup = document.getElementById("iframe-container");

    // 设置消息内容并显示弹窗
    popup.textContent = msg;
    popup.style.display = "block";

    // 1秒后自动隐藏弹窗
    setTimeout(() => {
        popup.style.display = "none";
    }, 1000); // 1000 毫秒 = 1 秒
}


function setLang() {
    document.querySelector("#appStoreLocal").innerHTML = chrome.i18n.getMessage("appStoreLocal");
    document.querySelector("#pushConfigLocal").innerHTML = chrome.i18n.getMessage("pushConfigLocal");
    document.querySelector("#saveLocal").innerHTML = chrome.i18n.getMessage("saveLocal");
    document.querySelector("#keyListLocal").innerHTML = chrome.i18n.getMessage("keyListLocal");
}



// 点击跳转到 App Store
document.getElementById("openAppStore").addEventListener("click", function () {
    browser.tabs.update({ url: "https://apps.apple.com/app/id6615073345"});
});

// 点击触发本地协议
document.getElementById("openLocal").addEventListener("click", function () {
//    window.location.href = "pb://";
    browser.tabs.update({ url: "pb://" });
});
