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

import ExtendInterface from './ExtendInterface';
import VerificationMode from './VerificationMode';
import ArgumentMatchers from './ArgumentMatchers';

class MockKit {
  constructor() {
    this.mFunctions = [];
    this.stubs = new Map();
    this.recordCalls = new Map();
    this.currentSetKey = new Map();
    this.mockObj = null;
    this.recordMockedMethod = new Map();
  }

  init() {
    this.reset();
  }

  reset() {
    this.mFunctions = [];
    this.stubs = {};
    this.recordCalls = {};
    this.currentSetKey = new Map();
    this.mockObj = null;
    this.recordMockedMethod = new Map();
  }

  clearAll() {
    this.reset();
    var props = Object.keys(this);
    for (var i = 0; i < props.length; i++) {
      delete this[props[i]];
    }

    var props = Object.getOwnPropertyNames(this);
    for (var i = 0; i < props.length; i++) {
      delete this[props[i]];
    }
    for (var key in this) {
      delete this[key];
    }
  }

  clear(obj) {
    if (!obj) {
      throw Error('Please enter an object to be cleaned');
    }
    if (typeof obj !== 'object' && typeof obj !== 'function') {
      throw new Error('Not a object or static class');
    }
    this.recordMockedMethod.forEach(function (value, key, map) {
      if (key) {
        obj[key] = value;
      }
    });
  }

  ignoreMock(obj, method) {
    if (typeof obj !== 'object' && typeof obj !== 'function') {
      throw new Error('Not a object or static class');
    }
    if (typeof method !== 'function') {
      throw new Error('Not a function');
    }
    let og = this.recordMockedMethod.get(method.propName);
    if (og) {
      obj[method.propName] = og;
      this.recordMockedMethod.set(method.propName, undefined);
    }
  }

  extend(dest, source) {
    dest['stub'] = source['stub'];
    dest['afterReturn'] = source['afterReturn'];
    dest['afterReturnNothing'] = source['afterReturnNothing'];
    dest['afterAction'] = source['afterAction'];
    dest['afterThrow'] = source['afterThrow'];
    dest['stubMockedCall'] = source['stubMockedCall'];
    dest['clear'] = source['clear'];
    return dest;
  }

  stubApply(f, params, returnInfo) {
    let values = this.stubs.get(f);
    if (!values) {
      values = new Map();
    }
    let key = params[0];
    if (typeof key === 'undefined') {
      key = 'anonymous-mock-' + f.propName;
    } else {
      key = [];
      const matcher = new ArgumentMatchers();
      for (let i = 0; i < params.length; i++) {
        const param = params[i];
        const matchKey = matcher.matcheStubKey(param);
        if (matchKey) {
          key.push(matchKey);
        } else {
          key.push(param);
        }
      }
    }
    this.currentSetKey.set(f, key);
    values.set(key, returnInfo);
    this.stubs.set(f, values);
  }

  getReturnInfo(f, params) {
    let values = this.stubs.get(f);
    if (!values) {
      return undefined;
    }
    let returnKet = params[0];
    const anonymousName = 'anonymous-mock-' + f.propName;
    if (typeof returnKet === 'undefined') {
      returnKet = anonymousName;
      let stubSetKey = this.currentSetKey.get(f);

      if (stubSetKey && (typeof (returnKet) !== 'undefined')) {
        returnKet = stubSetKey;
      }
    } else {
      returnKet = this.getReturnKet(values, params, returnKet, anonymousName);
    }

    return values.get(returnKet);
  }

  getReturnKet(values, params, defaultValue, anonymousName) {
    let flag = true;
    let returnKet = defaultValue;
    values.forEach((value, paramsKey, map) => {
      if (
        flag &&
        paramsKey !== anonymousName &&
        paramsKey.length === params.length &&
        this.checkIsRightValue(paramsKey, params)
      ) {
        returnKet = paramsKey;
        flag = false;
      }
    });
    return returnKet;
  }

  checkIsRightValue(paramsKey, params) {
    const matcher = new ArgumentMatchers();
    return paramsKey.every((key, j) => {
      if (ArgumentMatchers.isRegExp(key) && typeof params[j] === 'string') {
        return key.test(params[j]);
      }
      const matchKey = matcher.matcheReturnKey(params[j], undefined, key);
      if (matchKey && matchKey === key) {
        return true;
      } else if (this.checkIsEqual(params[j], key)) {
        return true;
      }
      return false;
    });
  }

  checkIsEqual(value1, value2) {
    if (value1 === value2) {
      return true;
    }
    if (typeof value1 !== typeof value2) {
      return false;
    }
    if (Array.isArray(value1) && Array.isArray(value2)) {
      if (value1.length !== value2.length) {
        return false;
      }
      for (let i = 0; i < value1.length; i++) {
        if (!this.checkIsEqual(value1[i], value2[i])) {
          return false;
        }
      }
      return true;
    }
    if (Object.prototype.toString.call(value1) === '[object Object]' &&
      Object.prototype.toString.call(value2) === '[object Object]') {
      const keys1 = Object.keys(value1);
      const keys2 = Object.keys(value2);
      if (keys1.length !== keys2.length) {
        return false;
      }
      for (let key of keys1) {
        if (!keys2.includes(key) || !this.checkIsEqual(value1[key], value2[key])) {
          return false;
        }
      }
      return true;
    }
    if (Object.prototype.toString.call(value1) === '[object Date]' &&
      Object.prototype.toString.call(value2) === '[object Date]' &&
      value1.getTime() === value2.getTime()) {
      return true;
    }
    if (Object.prototype.toString.call(value1) === '[object RegExp]' &&
      Object.prototype.toString.call(value2) === '[object RegExp]' &&
      value1.toString() === value2.toString()) {
      return true;
    }
    return false;
  }

  findName(obj, value) {
    let properties = this.findProperties(obj);
    let name = null;
    properties
      .filter((item) => item !== 'caller' && item !== 'arguments')
      .forEach(function (va1, idx, array) {
        if (obj[va1] === value) {
          name = va1;
        }
      });
    return name;
  }

  isFunctionFromPrototype(f, container, propName) {
    if (
      container.constructor !== Object &&
      container.constructor.prototype !== container
    ) {
      return container.constructor.prototype[propName] === f;
    }
    return false;
  }

  findProperties(obj, ...arg) {
    function getProperty(newObj) {
      if (newObj.__proto__ === null) {
        return [];
      }
      let properties = Object.getOwnPropertyNames(newObj);
      return [...properties, ...getProperty(newObj.__proto__)];
    }
    return getProperty(obj);
  }

  recordMethodCall(originalMethod, args) {
    Function.prototype.getName = function () {
      return this.name || this.toString().match(/function\s*([^(]*)\(/)[1];
    };
    let name = originalMethod.getName();
    let arglistString = name + '(' + Array.from(args).toString() + ')';
    let records = this.recordCalls.get(arglistString);
    if (!records) {
      records = 0;
    }
    records++;
    this.recordCalls.set(arglistString, records);
  }

  mockFunc(originalObject, originalMethod) {
    let tmp = this;
    this.originalMethod = originalMethod;
    let f = function () {
      let args = arguments;
      let action = tmp.getReturnInfo(f, args);
      if (originalMethod) {
        tmp.recordMethodCall(originalMethod, args);
      }
      if (action) {
        return action.apply(this, args);
      }
    };

    f.container = null || originalObject;
    f.original = originalMethod || null;

    if (originalObject && originalMethod) {
      if (typeof originalMethod !== 'function') {
        throw new Error('Not a function');
      }
      var name = this.findName(originalObject, originalMethod);
      originalObject[name] = f;
      this.recordMockedMethod.set(name, originalMethod);
      f.propName = name;
      f.originalFromPrototype = this.isFunctionFromPrototype(
        f.original,
        originalObject,
        f.propName
      );
    }
    f.mocker = this;
    this.mFunctions.push(f);
    this.extend(f, new ExtendInterface(this));
    return f;
  }

  verify(methodName, argsArray) {
    if (!methodName) {
      throw Error('not a function name');
    }
    let a = this.recordCalls.get(methodName + '(' + argsArray.toString() + ')');
    return new VerificationMode(a ? a : 0);
  }

  mockObject(object) {
    if (!object || typeof object === 'string') {
      throw Error(`this ${object} cannot be mocked`);
    }
    const _this = this;
    let mockedObject = {};
    let keys = Reflect.ownKeys(object);
    keys
      .filter((key) => typeof Reflect.get(object, key) === 'function')
      .forEach((key) => {
        mockedObject[key] = object[key];
        mockedObject[key] = _this.mockFunc(mockedObject, mockedObject[key]);
      });
    return mockedObject;
  }
}

function ifMockedFunction(f) {
  if (
    Object.prototype.toString.call(f) !== '[object Function]' &&
    Object.prototype.toString.call(f) !== '[object AsyncFunction]'
  ) {
    throw Error('not a function');
  }
  if (!f.stub) {
    throw Error('not a mock function');
  }
  return true;
}

function when(f) {
  if (!ifMockedFunction(f)) {
    throw Error('not a mock function');
  }
  return f.stub.bind(f);
}

export { MockKit, when };
