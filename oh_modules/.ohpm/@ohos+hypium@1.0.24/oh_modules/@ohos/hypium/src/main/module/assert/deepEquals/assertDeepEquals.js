/*
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import DeepTypeUtils from './DeepTypeUtils';
function assertDeepEquals(actualValue, expected) {
    let result = eq(actualValue, expected[0]);
    let msg = logMsg(actualValue, expected[0]);
    return {
        pass: result,
        message: msg
    };
}

function getMapLog(item) {
    let valueStr = '';
    let keyValue = '';
    if (item.length > 1) {
        let key = item[0];
        let value = item[1];
        if (value !== value) {
            valueStr = value;
        } else {
            valueStr = JSON.stringify(value);
        }
        keyValue = JSON.stringify(key);
    }
    return '[' + keyValue + ',' + valueStr + ']';
}

function getArrayLog(item) {
    // NAN
    if (item !== item) {
        return item;
    }
    if (item === undefined) {
        return 'undefined';
    }
    return JSON.stringify(item);
}


function getCollectionLog(data) {
    // 获取a的对象名称
    let finallyResult = '';
    const aClassName = Object.prototype.toString.call(data);
    if (aClassName === '[object Map]') {
        let result = Array.from(data);
        finallyResult = result.flatMap((item) => {
            return getMapLog(item);
        });
    }
    if (aClassName === '[object Set]') {
        let setArray = Array.from(data);
        finallyResult = setArray.flatMap((item) => {
            return getArrayLog(item);
        });
    }
    if (aClassName === '[object Array]') {
        finallyResult = data.flatMap((item) => {
            return getArrayLog(item);
        });
    }
    return finallyResult;
}

function getActualValueLog(actualValue) {
    // 获取a的对象名称
    const aClassName = Object.prototype.toString.call(actualValue);
    let actualMsg = '';
    if (aClassName === '[object Function]') {
        actualMsg = 'actualValue Function';
    } else if (aClassName === '[object Promise]') {
        actualMsg = 'actualValue Promise';
    } else if (aClassName === '[object Map]') {
        let finallyResult = getCollectionLog(actualValue);
        actualMsg = '[' + finallyResult + ']';
    } else if (aClassName === '[object Set]') {
        let flatMapResult = getCollectionLog(actualValue);
        actualMsg = '[' + flatMapResult + ']';
    } else if (aClassName === '[object Array]') {
        let flatMapResult = getCollectionLog(actualValue);
        actualMsg = '[' + flatMapResult + ']';
    } else if (aClassName === '[object RegExp]') {
        actualMsg = JSON.stringify(actualValue.source.replace('\\', ''));
    } else if (aClassName === '[object BigInt]') {
        actualMsg = actualValue;
    } else if (aClassName === '[object Error]') {
        actualMsg = actualValue.message;
    } else if (aClassName === '[object ArrayBuffer]') {
        actualMsg = actualValue.byteLength;
    }
    else {
        // NAN
        if (actualValue !== actualValue) {
            actualMsg = actualValue.toString();
        } else {
            actualMsg = JSON.stringify(actualValue);
        }
    }
    return actualMsg;
}

function getExpectedLog(expected) {
    const bClassName = Object.prototype.toString.call(expected);
    let expectMsg = '';
    if (bClassName === '[object Function]') {
        expectMsg = 'expected Function';
    } else if (bClassName === '[object Promise]') {
        expectMsg = 'expected Promise';
    } else if (bClassName === '[object Map]') {
        let finallyResult = getCollectionLog(expected);
        expectMsg = '[' + finallyResult + ']';
    } else if (bClassName === '[object Set]') {
        let flatMapResult = getCollectionLog(expected);
        expectMsg = '[' + flatMapResult + ']';
    } else if (bClassName === '[object Array]') {
        let flatMapResult = getCollectionLog(expected);
        expectMsg = '[' + flatMapResult + ']';
    } else if (bClassName === '[object RegExp]') {
        expectMsg = JSON.stringify(expected.source.replace('\\', ''));
    } else if (bClassName === '[object BigInt]') {
        expectMsg = expected;
    } else if (bClassName === '[object Error]') {
        expectMsg = expected.message;
    } else if (bClassName === '[object ArrayBuffer]') {
        expectMsg = expected.byteLength;
    }
    else {
        // NAN
        if (expected !== expected) {
            expectMsg = expected.toString();
        } else {
            expectMsg = JSON.stringify(expected);
        }
    }
    return expectMsg;
}

/**
 * 获取失败显示日志
 * @param actualValue 实际对象
 * @param expected 期待比较对象
 */
function logMsg(actualValue, expected) {
    // 获取a的对象名称
    let actualMsg = getActualValueLog(actualValue);
    let expectMsg = getExpectedLog(expected);

    return 'expect ' + actualMsg + ' deep equals ' + expectMsg;
}

function eq(a, b) {
    let result = true;

    if (a === b) {
        result = a !== 0 || 1 / a === 1 / b;
        return result;
    }

    if (a === null || b === null) {
        result = a === b;
        return result;
    }
    // 获取a的对象名称
    const aClassName = Object.prototype.toString.call(a);
    const bClassName = Object.prototype.toString.call(b);
    // 不同类型不同对象
    if (aClassName !== bClassName) {
        return false;
    }
    if (aClassName === '[object String]' || aClassName === '[object Number]' || aClassName === '[object Date]' ||
        aClassName === '[object Boolean]' || aClassName === '[object ArrayBuffer]' ||
        aClassName === '[object RegExp]' || aClassName === '[object Error]') {
        result = isEqualSampleObj(a, b);
        return result;
    }

    if (typeof a !== 'object' || typeof b !== 'object') {
        return false;
    }

    if (DeepTypeUtils.isDomNode(a) || DeepTypeUtils.isPromise(a) || DeepTypeUtils.isFunction(a)) {
        result = isEqualNodeOrPromiseOrFunction(a, b);
        return result;
    }

    if (aClassName === '[object Array]' || aClassName === '[object Map]' || aClassName === '[object Set]') {
        result = isEqualCollection(a, b);
        return result;
    }

    result = isEqualObj(a, b);
    return result;
}

function isEqualNodeOrPromiseOrFunction(a, b) {
    let equalNodeOrPromiseOrFunction = true;
    if (DeepTypeUtils.isDomNode(a) && DeepTypeUtils.isDomNode(b)) {
        const aIsDomNode = DeepTypeUtils.isDomNode(a);
        const bIsDomNode = DeepTypeUtils.isDomNode(b);
        if (aIsDomNode && bIsDomNode) {
            // At first try to use DOM3 method isEqualNode
            equalNodeOrPromiseOrFunction = a.isEqualNode(b);
            return equalNodeOrPromiseOrFunction;
        }
        if (aIsDomNode || bIsDomNode) {
            equalNodeOrPromiseOrFunction = false;
            return false;
        }
    }

    if (DeepTypeUtils.isPromise(a) && DeepTypeUtils.isPromise(b)) {
        const aIsPromise = DeepTypeUtils.isPromise(a);
        const bIsPromise = DeepTypeUtils.isPromise(b);
        // 俩个Promise对象
        if (aIsPromise && bIsPromise) {
            equalNodeOrPromiseOrFunction = a === b;
            return a === b;
        }
    }
    if (DeepTypeUtils.isFunction(a) && DeepTypeUtils.isFunction(b)) {
        // 俩个函数对象
        const aCtor = a.constructor,
            bCtor = b.constructor;
        if (
            aCtor !== bCtor &&
            DeepTypeUtils.isFunction(aCtor) &&
            DeepTypeUtils.isFunction(bCtor) &&
                a instanceof aCtor &&
                b instanceof bCtor &&
                !(aCtor instanceof aCtor && bCtor instanceof bCtor)
        ) {
            equalNodeOrPromiseOrFunction = false;
            return false;
        }
    }
    return equalNodeOrPromiseOrFunction;
}

function isEqualCollection(a, b) {
    let equalCollection = true;
    // 获取a的对象名称
    const aClassName = Object.prototype.toString.call(a);
    const bClassName = Object.prototype.toString.call(b);
    // 都是数组
    if (aClassName === '[object Array]') {
        equalCollection = isEqualArray(a, b);
        return equalCollection;
    }

    // 都是Map
    if (DeepTypeUtils.isMap(a) && DeepTypeUtils.isMap(b)) {
        equalCollection = isEqualMap(a, b);
        return equalCollection;
    }

    // 都是Set
    if (DeepTypeUtils.isSet(a) && DeepTypeUtils.isSet(b)) {
        equalCollection = isEqualSet(a, b);
        return equalCollection;
    }

    return true;
}

function isEqualSampleObj(a, b) {
    let equalSampleObj = true;
    const aClassName = Object.prototype.toString.call(a);
    const bClassName = Object.prototype.toString.call(b);
    // 俩个string对象
    if (aClassName === '[object String]') {
        equalSampleObj = a === String(b);
        return equalSampleObj;
    }
    // 俩个Number对象
    if (aClassName === '[object Number]') {
        // NAN
        if (a !== a && b !== b) {
            return a === b;
        }
        equalSampleObj = a !== +a ? b !== +b : a === 0 && b === 0 ? 1 / a === 1 / b : a === +b;
        return equalSampleObj;
    }

    // 俩个Date对象/ boolean对象
    if (aClassName === '[object Date]' || aClassName === '[object Boolean]') {
        equalSampleObj = +a === +b;
        return equalSampleObj;
    }

    // 俩个ArrayBuffer
    if (aClassName === '[object ArrayBuffer]') {
        equalSampleObj = eq(new Uint8Array(a), new Uint8Array(b));
        return equalSampleObj;
    }

    // 正则表达式
    if (aClassName === '[object RegExp]') {
        return (
            a.source === b.source &&
                a.global === b.global &&
                a.multiline === b.multiline &&
                a.ignoreCase === b.ignoreCase
        );
    }

    if (a instanceof Error && b instanceof Error) {
        equalSampleObj = a.message === b.message;
        return equalSampleObj;
    }

    return equalSampleObj;
}

function isEqualObj(a, b) {
    let equalObj = true;
    const aClassName = Object.prototype.toString.call(a);
    const bClassName = Object.prototype.toString.call(b);
    const aKeys = DeepTypeUtils.keys(a, aClassName === '[object Array]');
    let size = aKeys.length;

    // 俩个对象属性长度不一致， 俩对象不相同
    if (DeepTypeUtils.keys(b, bClassName === '[object Array]').length !== size) {
        return false;
    }

    // 俩对象属性数量相同， 递归比较每个属性值得值
    for (const key of aKeys) {
        // b 没有 key 属性
        if (!DeepTypeUtils.has(b, key)) {
            equalObj = false;
            continue;
        }
        if (!eq(a[key], b[key])) {
            equalObj = false;
        }
    }
    return equalObj;
}

function isEqualArray(a, b) {
    let equalArray = true;
    const aLength = a.length;
    const bLength = b.length;
    if (aLength !== bLength) {
        // 数组长度不同，不是同一个对象
        return false;
    }
    for (let i = 0; i < aLength || i < bLength; i++) {
        // 递归每一个元素是否相同
        equalArray = eq(i < aLength ? a[i] : void 0, i < bLength ? b[i] : void 0) && equalArray;
    }
    return equalArray;
}

function isEqualMap(a, b) {
    let equalMap = true;
    if (a.size !== b.size) {
        return false;
    }
    const keysA = [];
    const keysB = [];
    a.forEach(function(valueA, keyA) {
        keysA.push(keyA);
    });
    b.forEach(function(valueB, keyB) {
        keysB.push(keyB);
    });
    const mapKeys = [keysA, keysB];
    const cmpKeys = [keysB, keysA];
    for (let i = 0; equalMap && i < mapKeys.length; i++) {
        const mapIter = mapKeys[i];
        const cmpIter = cmpKeys[i];

        for (let j = 0; equalMap && j < mapIter.length; j++) {
            const mapKey = mapIter[j];
            const cmpKey = cmpIter[j];
            const mapValueA = a.get(mapKey);
            let mapValueB;
            if (eq(mapKey, cmpKey)) {
                mapValueB = b.get(cmpKey);
            } else {
                mapValueB = b.get(mapKey);
            }
            equalMap = eq(mapValueA, mapValueB);
        }
    }
    return equalMap;
}

function isEqualSet(a, b) {
    let equalSet = true;
    if (a.size !== b.size) {
        return false;
    }
    const valuesA = [];
    a.forEach(function(valueA) {
        valuesA.push(valueA);
    });
    const valuesB = [];
    b.forEach(function(valueB) {
        valuesB.push(valueB);
    });
    const setPairs = [[valuesA, valuesB], [valuesB, valuesA]];
    for (let i = 0; equalSet && i < setPairs.length; i++) {
        const baseValues = setPairs[i][0];
        const otherValues = setPairs[i][1];
        for (const baseValue of baseValues) {
            let found = false;
            for (let j = 0; !found && j < otherValues.length; j++) {
                const otherValue = otherValues[j];
                // 深度比较对象
                found = eq(baseValue, otherValue);
            }
            equalSet = equalSet && found;
        }
    }
    return equalSet;
}

export default assertDeepEquals;
