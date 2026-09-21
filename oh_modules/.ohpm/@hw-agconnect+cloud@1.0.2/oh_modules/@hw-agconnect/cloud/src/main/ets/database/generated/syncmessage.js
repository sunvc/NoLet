/*eslint-disable block-scoped-var, id-length, no-control-regex, no-magic-numbers, no-prototype-builtins, no-redeclare, no-shadow, no-var, sort-vars*/
import protobuf from "protobufjs";
import Long from "long";

let $protobuf = protobuf
$protobuf.util.Long = Long;
$protobuf.configure();


// Common aliases
const $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;

// Exported root namespace
const $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});

export const naturalcloudsyncv2 = $root.naturalcloudsyncv2 = (() => {

    /**
     * Namespace naturalcloudsyncv2.
     * @exports naturalcloudsyncv2
     * @namespace
     */
    const naturalcloudsyncv2 = {};

    naturalcloudsyncv2.Schema = (function() {

        /**
         * Properties of a Schema.
         * @memberof naturalcloudsyncv2
         * @interface ISchema
         * @property {string|null} [n] Schema n
         * @property {Array.<naturalcloudsyncv2.ISchemaField>|null} [fs] Schema fs
         */

        /**
         * Constructs a new Schema.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a Schema.
         * @implements ISchema
         * @constructor
         * @param {naturalcloudsyncv2.ISchema=} [properties] Properties to set
         */
        function Schema(properties) {
            this.fs = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * Schema n.
         * @member {string} n
         * @memberof naturalcloudsyncv2.Schema
         * @instance
         */
        Schema.prototype.n = "";

        /**
         * Schema fs.
         * @member {Array.<naturalcloudsyncv2.ISchemaField>} fs
         * @memberof naturalcloudsyncv2.Schema
         * @instance
         */
        Schema.prototype.fs = $util.emptyArray;

        /**
         * Creates a new Schema instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {naturalcloudsyncv2.ISchema=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.Schema} Schema instance
         */
        Schema.create = function create(properties) {
            return new Schema(properties);
        };

        /**
         * Encodes the specified Schema message. Does not implicitly {@link naturalcloudsyncv2.Schema.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {naturalcloudsyncv2.ISchema} message Schema message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Schema.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.n != null && Object.hasOwnProperty.call(message, "n"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.n);
            if (message.fs != null && message.fs.length)
                for (let i = 0; i < message.fs.length; ++i)
                    $root.naturalcloudsyncv2.SchemaField.encode(message.fs[i], writer.uint32(/* id 2, wireType 2 =*/18).fork()).ldelim();
            return writer;
        };

        /**
         * Encodes the specified Schema message, length delimited. Does not implicitly {@link naturalcloudsyncv2.Schema.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {naturalcloudsyncv2.ISchema} message Schema message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Schema.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a Schema message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.Schema} Schema
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Schema.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.Schema();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.n = reader.string();
                        break;
                    }
                case 2: {
                        if (!(message.fs && message.fs.length))
                            message.fs = [];
                        message.fs.push($root.naturalcloudsyncv2.SchemaField.decode(reader, reader.uint32()));
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a Schema message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.Schema} Schema
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Schema.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a Schema message.
         * @function verify
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        Schema.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.n != null && message.hasOwnProperty("n"))
                if (!$util.isString(message.n))
                    return "n: string expected";
            if (message.fs != null && message.hasOwnProperty("fs")) {
                if (!Array.isArray(message.fs))
                    return "fs: array expected";
                for (let i = 0; i < message.fs.length; ++i) {
                    let error = $root.naturalcloudsyncv2.SchemaField.verify(message.fs[i]);
                    if (error)
                        return "fs." + error;
                }
            }
            return null;
        };

        /**
         * Creates a Schema message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.Schema} Schema
         */
        Schema.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.Schema)
                return object;
            let message = new $root.naturalcloudsyncv2.Schema();
            if (object.n != null)
                message.n = String(object.n);
            if (object.fs) {
                if (!Array.isArray(object.fs))
                    throw TypeError(".naturalcloudsyncv2.Schema.fs: array expected");
                message.fs = [];
                for (let i = 0; i < object.fs.length; ++i) {
                    if (typeof object.fs[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.Schema.fs: object expected");
                    message.fs[i] = $root.naturalcloudsyncv2.SchemaField.fromObject(object.fs[i]);
                }
            }
            return message;
        };

        /**
         * Creates a plain object from a Schema message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {naturalcloudsyncv2.Schema} message Schema
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        Schema.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.arrays || options.defaults)
                object.fs = [];
            if (options.defaults)
                object.n = "";
            if (message.n != null && message.hasOwnProperty("n"))
                object.n = message.n;
            if (message.fs && message.fs.length) {
                object.fs = [];
                for (let j = 0; j < message.fs.length; ++j)
                    object.fs[j] = $root.naturalcloudsyncv2.SchemaField.toObject(message.fs[j], options);
            }
            return object;
        };

        /**
         * Converts this Schema to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.Schema
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        Schema.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for Schema
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.Schema
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        Schema.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.Schema";
        };

        return Schema;
    })();

    naturalcloudsyncv2.SchemaField = (function() {

        /**
         * Properties of a SchemaField.
         * @memberof naturalcloudsyncv2
         * @interface ISchemaField
         * @property {string|null} [n] SchemaField n
         * @property {naturalcloudsyncv2.FieldType|null} [t] SchemaField t
         * @property {boolean|null} [p] SchemaField p
         * @property {boolean|null} [e] SchemaField e
         * @property {boolean|null} [nn] SchemaField nn
         * @property {boolean|null} [df] SchemaField df
         * @property {boolean|null} [bl] SchemaField bl
         * @property {number|null} [b] SchemaField b
         * @property {number|null} [st] SchemaField st
         * @property {number|null} [i] SchemaField i
         * @property {Long|null} [l] SchemaField l
         * @property {number|null} [f] SchemaField f
         * @property {number|null} [d] SchemaField d
         * @property {Uint8Array|null} [ba] SchemaField ba
         * @property {string|null} [s] SchemaField s
         */

        /**
         * Constructs a new SchemaField.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a SchemaField.
         * @implements ISchemaField
         * @constructor
         * @param {naturalcloudsyncv2.ISchemaField=} [properties] Properties to set
         */
        function SchemaField(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * SchemaField n.
         * @member {string} n
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.n = "";

        /**
         * SchemaField t.
         * @member {naturalcloudsyncv2.FieldType} t
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.t = 0;

        /**
         * SchemaField p.
         * @member {boolean} p
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.p = false;

        /**
         * SchemaField e.
         * @member {boolean} e
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.e = false;

        /**
         * SchemaField nn.
         * @member {boolean} nn
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.nn = false;

        /**
         * SchemaField df.
         * @member {boolean} df
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.df = false;

        /**
         * SchemaField bl.
         * @member {boolean|null|undefined} bl
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.bl = null;

        /**
         * SchemaField b.
         * @member {number|null|undefined} b
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.b = null;

        /**
         * SchemaField st.
         * @member {number|null|undefined} st
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.st = null;

        /**
         * SchemaField i.
         * @member {number|null|undefined} i
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.i = null;

        /**
         * SchemaField l.
         * @member {Long|null|undefined} l
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.l = null;

        /**
         * SchemaField f.
         * @member {number|null|undefined} f
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.f = null;

        /**
         * SchemaField d.
         * @member {number|null|undefined} d
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.d = null;

        /**
         * SchemaField ba.
         * @member {Uint8Array|null|undefined} ba
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.ba = null;

        /**
         * SchemaField s.
         * @member {string|null|undefined} s
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        SchemaField.prototype.s = null;

        // OneOf field names bound to virtual getters and setters
        let $oneOfFields;

        /**
         * SchemaField defaultValue.
         * @member {"bl"|"b"|"st"|"i"|"l"|"f"|"d"|"ba"|"s"|undefined} defaultValue
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         */
        Object.defineProperty(SchemaField.prototype, "defaultValue", {
            get: $util.oneOfGetter($oneOfFields = ["bl", "b", "st", "i", "l", "f", "d", "ba", "s"]),
            set: $util.oneOfSetter($oneOfFields)
        });

        /**
         * Creates a new SchemaField instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {naturalcloudsyncv2.ISchemaField=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.SchemaField} SchemaField instance
         */
        SchemaField.create = function create(properties) {
            return new SchemaField(properties);
        };

        /**
         * Encodes the specified SchemaField message. Does not implicitly {@link naturalcloudsyncv2.SchemaField.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {naturalcloudsyncv2.ISchemaField} message SchemaField message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SchemaField.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.n != null && Object.hasOwnProperty.call(message, "n"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.n);
            if (message.t != null && Object.hasOwnProperty.call(message, "t"))
                writer.uint32(/* id 2, wireType 0 =*/16).int32(message.t);
            if (message.p != null && Object.hasOwnProperty.call(message, "p"))
                writer.uint32(/* id 3, wireType 0 =*/24).bool(message.p);
            if (message.e != null && Object.hasOwnProperty.call(message, "e"))
                writer.uint32(/* id 4, wireType 0 =*/32).bool(message.e);
            if (message.nn != null && Object.hasOwnProperty.call(message, "nn"))
                writer.uint32(/* id 5, wireType 0 =*/40).bool(message.nn);
            if (message.df != null && Object.hasOwnProperty.call(message, "df"))
                writer.uint32(/* id 6, wireType 0 =*/48).bool(message.df);
            if (message.bl != null && Object.hasOwnProperty.call(message, "bl"))
                writer.uint32(/* id 7, wireType 0 =*/56).bool(message.bl);
            if (message.b != null && Object.hasOwnProperty.call(message, "b"))
                writer.uint32(/* id 8, wireType 0 =*/64).int32(message.b);
            if (message.st != null && Object.hasOwnProperty.call(message, "st"))
                writer.uint32(/* id 9, wireType 0 =*/72).int32(message.st);
            if (message.i != null && Object.hasOwnProperty.call(message, "i"))
                writer.uint32(/* id 10, wireType 0 =*/80).int32(message.i);
            if (message.l != null && Object.hasOwnProperty.call(message, "l"))
                writer.uint32(/* id 11, wireType 0 =*/88).int64(message.l);
            if (message.f != null && Object.hasOwnProperty.call(message, "f"))
                writer.uint32(/* id 12, wireType 5 =*/101).float(message.f);
            if (message.d != null && Object.hasOwnProperty.call(message, "d"))
                writer.uint32(/* id 13, wireType 1 =*/105).double(message.d);
            if (message.ba != null && Object.hasOwnProperty.call(message, "ba"))
                writer.uint32(/* id 14, wireType 2 =*/114).bytes(message.ba);
            if (message.s != null && Object.hasOwnProperty.call(message, "s"))
                writer.uint32(/* id 15, wireType 2 =*/122).string(message.s);
            return writer;
        };

        /**
         * Encodes the specified SchemaField message, length delimited. Does not implicitly {@link naturalcloudsyncv2.SchemaField.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {naturalcloudsyncv2.ISchemaField} message SchemaField message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SchemaField.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a SchemaField message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.SchemaField} SchemaField
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SchemaField.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.SchemaField();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.n = reader.string();
                        break;
                    }
                case 2: {
                        message.t = reader.int32();
                        break;
                    }
                case 3: {
                        message.p = reader.bool();
                        break;
                    }
                case 4: {
                        message.e = reader.bool();
                        break;
                    }
                case 5: {
                        message.nn = reader.bool();
                        break;
                    }
                case 6: {
                        message.df = reader.bool();
                        break;
                    }
                case 7: {
                        message.bl = reader.bool();
                        break;
                    }
                case 8: {
                        message.b = reader.int32();
                        break;
                    }
                case 9: {
                        message.st = reader.int32();
                        break;
                    }
                case 10: {
                        message.i = reader.int32();
                        break;
                    }
                case 11: {
                        message.l = reader.int64();
                        break;
                    }
                case 12: {
                        message.f = reader.float();
                        break;
                    }
                case 13: {
                        message.d = reader.double();
                        break;
                    }
                case 14: {
                        message.ba = reader.bytes();
                        break;
                    }
                case 15: {
                        message.s = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a SchemaField message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.SchemaField} SchemaField
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SchemaField.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a SchemaField message.
         * @function verify
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        SchemaField.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            let properties = {};
            if (message.n != null && message.hasOwnProperty("n"))
                if (!$util.isString(message.n))
                    return "n: string expected";
            if (message.t != null && message.hasOwnProperty("t"))
                switch (message.t) {
                default:
                    return "t: enum value expected";
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                case 9:
                case 10:
                case 11:
                case 12:
                case 13:
                    break;
                }
            if (message.p != null && message.hasOwnProperty("p"))
                if (typeof message.p !== "boolean")
                    return "p: boolean expected";
            if (message.e != null && message.hasOwnProperty("e"))
                if (typeof message.e !== "boolean")
                    return "e: boolean expected";
            if (message.nn != null && message.hasOwnProperty("nn"))
                if (typeof message.nn !== "boolean")
                    return "nn: boolean expected";
            if (message.df != null && message.hasOwnProperty("df"))
                if (typeof message.df !== "boolean")
                    return "df: boolean expected";
            if (message.bl != null && message.hasOwnProperty("bl")) {
                properties.defaultValue = 1;
                if (typeof message.bl !== "boolean")
                    return "bl: boolean expected";
            }
            if (message.b != null && message.hasOwnProperty("b")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (!$util.isInteger(message.b))
                    return "b: integer expected";
            }
            if (message.st != null && message.hasOwnProperty("st")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (!$util.isInteger(message.st))
                    return "st: integer expected";
            }
            if (message.i != null && message.hasOwnProperty("i")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (!$util.isInteger(message.i))
                    return "i: integer expected";
            }
            if (message.l != null && message.hasOwnProperty("l")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (!$util.isInteger(message.l) && !(message.l && $util.isInteger(message.l.low) && $util.isInteger(message.l.high)))
                    return "l: integer|Long expected";
            }
            if (message.f != null && message.hasOwnProperty("f")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (typeof message.f !== "number")
                    return "f: number expected";
            }
            if (message.d != null && message.hasOwnProperty("d")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (typeof message.d !== "number")
                    return "d: number expected";
            }
            if (message.ba != null && message.hasOwnProperty("ba")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (!(message.ba && typeof message.ba.length === "number" || $util.isString(message.ba)))
                    return "ba: buffer expected";
            }
            if (message.s != null && message.hasOwnProperty("s")) {
                if (properties.defaultValue === 1)
                    return "defaultValue: multiple values";
                properties.defaultValue = 1;
                if (!$util.isString(message.s))
                    return "s: string expected";
            }
            return null;
        };

        /**
         * Creates a SchemaField message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.SchemaField} SchemaField
         */
        SchemaField.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.SchemaField)
                return object;
            let message = new $root.naturalcloudsyncv2.SchemaField();
            if (object.n != null)
                message.n = String(object.n);
            switch (object.t) {
            default:
                if (typeof object.t === "number") {
                    message.t = object.t;
                    break;
                }
                break;
            case "TYPE_DEFAULT":
            case 0:
                message.t = 0;
                break;
            case "TYPE_BOOLEAN":
            case 1:
                message.t = 1;
                break;
            case "TYPE_BYTE":
            case 2:
                message.t = 2;
                break;
            case "TYPE_SHORT":
            case 3:
                message.t = 3;
                break;
            case "TYPE_INT32":
            case 4:
                message.t = 4;
                break;
            case "TYPE_LONG":
            case 5:
                message.t = 5;
                break;
            case "TYPE_FLOAT":
            case 6:
                message.t = 6;
                break;
            case "TYPE_DOUBLE":
            case 7:
                message.t = 7;
                break;
            case "TYPE_BYTE_ARRAY":
            case 8:
                message.t = 8;
                break;
            case "TYPE_STRING":
            case 9:
                message.t = 9;
                break;
            case "TYPE_DATE":
            case 10:
                message.t = 10;
                break;
            case "TYPE_TEXT":
            case 11:
                message.t = 11;
                break;
            case "TYPE_AUTO_INCREMENT_INT":
            case 12:
                message.t = 12;
                break;
            case "TYPE_AUTO_INCREMENT_LONG":
            case 13:
                message.t = 13;
                break;
            }
            if (object.p != null)
                message.p = Boolean(object.p);
            if (object.e != null)
                message.e = Boolean(object.e);
            if (object.nn != null)
                message.nn = Boolean(object.nn);
            if (object.df != null)
                message.df = Boolean(object.df);
            if (object.bl != null)
                message.bl = Boolean(object.bl);
            if (object.b != null)
                message.b = object.b | 0;
            if (object.st != null)
                message.st = object.st | 0;
            if (object.i != null)
                message.i = object.i | 0;
            if (object.l != null)
                if ($util.Long)
                    (message.l = $util.Long.fromValue(object.l)).unsigned = false;
                else if (typeof object.l === "string")
                    message.l = parseInt(object.l, 10);
                else if (typeof object.l === "number")
                    message.l = object.l;
                else if (typeof object.l === "object")
                    message.l = new $util.LongBits(object.l.low >>> 0, object.l.high >>> 0).toNumber();
            if (object.f != null)
                message.f = Number(object.f);
            if (object.d != null)
                message.d = Number(object.d);
            if (object.ba != null)
                if (typeof object.ba === "string")
                    $util.base64.decode(object.ba, message.ba = $util.newBuffer($util.base64.length(object.ba)), 0);
                else if (object.ba.length >= 0)
                    message.ba = object.ba;
            if (object.s != null)
                message.s = String(object.s);
            return message;
        };

        /**
         * Creates a plain object from a SchemaField message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {naturalcloudsyncv2.SchemaField} message SchemaField
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        SchemaField.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.n = "";
                object.t = options.enums === String ? "TYPE_DEFAULT" : 0;
                object.p = false;
                object.e = false;
                object.nn = false;
                object.df = false;
            }
            if (message.n != null && message.hasOwnProperty("n"))
                object.n = message.n;
            if (message.t != null && message.hasOwnProperty("t"))
                object.t = options.enums === String ? $root.naturalcloudsyncv2.FieldType[message.t] === undefined ? message.t : $root.naturalcloudsyncv2.FieldType[message.t] : message.t;
            if (message.p != null && message.hasOwnProperty("p"))
                object.p = message.p;
            if (message.e != null && message.hasOwnProperty("e"))
                object.e = message.e;
            if (message.nn != null && message.hasOwnProperty("nn"))
                object.nn = message.nn;
            if (message.df != null && message.hasOwnProperty("df"))
                object.df = message.df;
            if (message.bl != null && message.hasOwnProperty("bl")) {
                object.bl = message.bl;
                if (options.oneofs)
                    object.defaultValue = "bl";
            }
            if (message.b != null && message.hasOwnProperty("b")) {
                object.b = message.b;
                if (options.oneofs)
                    object.defaultValue = "b";
            }
            if (message.st != null && message.hasOwnProperty("st")) {
                object.st = message.st;
                if (options.oneofs)
                    object.defaultValue = "st";
            }
            if (message.i != null && message.hasOwnProperty("i")) {
                object.i = message.i;
                if (options.oneofs)
                    object.defaultValue = "i";
            }
            if (message.l != null && message.hasOwnProperty("l")) {
                if (typeof message.l === "number")
                    object.l = options.longs === String ? String(message.l) : message.l;
                else
                    object.l = options.longs === String ? $util.Long.prototype.toString.call(message.l) : options.longs === Number ? new $util.LongBits(message.l.low >>> 0, message.l.high >>> 0).toNumber() : message.l;
                if (options.oneofs)
                    object.defaultValue = "l";
            }
            if (message.f != null && message.hasOwnProperty("f")) {
                object.f = options.json && !isFinite(message.f) ? String(message.f) : message.f;
                if (options.oneofs)
                    object.defaultValue = "f";
            }
            if (message.d != null && message.hasOwnProperty("d")) {
                object.d = options.json && !isFinite(message.d) ? String(message.d) : message.d;
                if (options.oneofs)
                    object.defaultValue = "d";
            }
            if (message.ba != null && message.hasOwnProperty("ba")) {
                object.ba = options.bytes === String ? $util.base64.encode(message.ba, 0, message.ba.length) : options.bytes === Array ? Array.prototype.slice.call(message.ba) : message.ba;
                if (options.oneofs)
                    object.defaultValue = "ba";
            }
            if (message.s != null && message.hasOwnProperty("s")) {
                object.s = message.s;
                if (options.oneofs)
                    object.defaultValue = "s";
            }
            return object;
        };

        /**
         * Converts this SchemaField to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.SchemaField
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        SchemaField.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for SchemaField
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.SchemaField
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        SchemaField.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.SchemaField";
        };

        return SchemaField;
    })();

    /**
     * FieldType enum.
     * @name naturalcloudsyncv2.FieldType
     * @enum {number}
     * @property {number} TYPE_DEFAULT=0 TYPE_DEFAULT value
     * @property {number} TYPE_BOOLEAN=1 TYPE_BOOLEAN value
     * @property {number} TYPE_BYTE=2 TYPE_BYTE value
     * @property {number} TYPE_SHORT=3 TYPE_SHORT value
     * @property {number} TYPE_INT32=4 TYPE_INT32 value
     * @property {number} TYPE_LONG=5 TYPE_LONG value
     * @property {number} TYPE_FLOAT=6 TYPE_FLOAT value
     * @property {number} TYPE_DOUBLE=7 TYPE_DOUBLE value
     * @property {number} TYPE_BYTE_ARRAY=8 TYPE_BYTE_ARRAY value
     * @property {number} TYPE_STRING=9 TYPE_STRING value
     * @property {number} TYPE_DATE=10 TYPE_DATE value
     * @property {number} TYPE_TEXT=11 TYPE_TEXT value
     * @property {number} TYPE_AUTO_INCREMENT_INT=12 TYPE_AUTO_INCREMENT_INT value
     * @property {number} TYPE_AUTO_INCREMENT_LONG=13 TYPE_AUTO_INCREMENT_LONG value
     */
    naturalcloudsyncv2.FieldType = (function() {
        const valuesById = {}, values = Object.create(valuesById);
        values[valuesById[0] = "TYPE_DEFAULT"] = 0;
        values[valuesById[1] = "TYPE_BOOLEAN"] = 1;
        values[valuesById[2] = "TYPE_BYTE"] = 2;
        values[valuesById[3] = "TYPE_SHORT"] = 3;
        values[valuesById[4] = "TYPE_INT32"] = 4;
        values[valuesById[5] = "TYPE_LONG"] = 5;
        values[valuesById[6] = "TYPE_FLOAT"] = 6;
        values[valuesById[7] = "TYPE_DOUBLE"] = 7;
        values[valuesById[8] = "TYPE_BYTE_ARRAY"] = 8;
        values[valuesById[9] = "TYPE_STRING"] = 9;
        values[valuesById[10] = "TYPE_DATE"] = 10;
        values[valuesById[11] = "TYPE_TEXT"] = 11;
        values[valuesById[12] = "TYPE_AUTO_INCREMENT_INT"] = 12;
        values[valuesById[13] = "TYPE_AUTO_INCREMENT_LONG"] = 13;
        return values;
    })();

    naturalcloudsyncv2.OperationData = (function() {

        /**
         * Properties of an OperationData.
         * @memberof naturalcloudsyncv2
         * @interface IOperationData
         * @property {Array.<naturalcloudsyncv2.IObj>|null} [os] OperationData os
         * @property {number|null} [t] OperationData t
         * @property {number|null} [i] OperationData i
         */

        /**
         * Constructs a new OperationData.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an OperationData.
         * @implements IOperationData
         * @constructor
         * @param {naturalcloudsyncv2.IOperationData=} [properties] Properties to set
         */
        function OperationData(properties) {
            this.os = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * OperationData os.
         * @member {Array.<naturalcloudsyncv2.IObj>} os
         * @memberof naturalcloudsyncv2.OperationData
         * @instance
         */
        OperationData.prototype.os = $util.emptyArray;

        /**
         * OperationData t.
         * @member {number} t
         * @memberof naturalcloudsyncv2.OperationData
         * @instance
         */
        OperationData.prototype.t = 0;

        /**
         * OperationData i.
         * @member {number} i
         * @memberof naturalcloudsyncv2.OperationData
         * @instance
         */
        OperationData.prototype.i = 0;

        /**
         * Creates a new OperationData instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {naturalcloudsyncv2.IOperationData=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.OperationData} OperationData instance
         */
        OperationData.create = function create(properties) {
            return new OperationData(properties);
        };

        /**
         * Encodes the specified OperationData message. Does not implicitly {@link naturalcloudsyncv2.OperationData.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {naturalcloudsyncv2.IOperationData} message OperationData message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        OperationData.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.os != null && message.os.length)
                for (let i = 0; i < message.os.length; ++i)
                    $root.naturalcloudsyncv2.Obj.encode(message.os[i], writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
            if (message.t != null && Object.hasOwnProperty.call(message, "t"))
                writer.uint32(/* id 2, wireType 0 =*/16).int32(message.t);
            if (message.i != null && Object.hasOwnProperty.call(message, "i"))
                writer.uint32(/* id 3, wireType 0 =*/24).int32(message.i);
            return writer;
        };

        /**
         * Encodes the specified OperationData message, length delimited. Does not implicitly {@link naturalcloudsyncv2.OperationData.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {naturalcloudsyncv2.IOperationData} message OperationData message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        OperationData.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an OperationData message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.OperationData} OperationData
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        OperationData.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.OperationData();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        if (!(message.os && message.os.length))
                            message.os = [];
                        message.os.push($root.naturalcloudsyncv2.Obj.decode(reader, reader.uint32()));
                        break;
                    }
                case 2: {
                        message.t = reader.int32();
                        break;
                    }
                case 3: {
                        message.i = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an OperationData message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.OperationData} OperationData
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        OperationData.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an OperationData message.
         * @function verify
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        OperationData.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.os != null && message.hasOwnProperty("os")) {
                if (!Array.isArray(message.os))
                    return "os: array expected";
                for (let i = 0; i < message.os.length; ++i) {
                    let error = $root.naturalcloudsyncv2.Obj.verify(message.os[i]);
                    if (error)
                        return "os." + error;
                }
            }
            if (message.t != null && message.hasOwnProperty("t"))
                if (!$util.isInteger(message.t))
                    return "t: integer expected";
            if (message.i != null && message.hasOwnProperty("i"))
                if (!$util.isInteger(message.i))
                    return "i: integer expected";
            return null;
        };

        /**
         * Creates an OperationData message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.OperationData} OperationData
         */
        OperationData.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.OperationData)
                return object;
            let message = new $root.naturalcloudsyncv2.OperationData();
            if (object.os) {
                if (!Array.isArray(object.os))
                    throw TypeError(".naturalcloudsyncv2.OperationData.os: array expected");
                message.os = [];
                for (let i = 0; i < object.os.length; ++i) {
                    if (typeof object.os[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.OperationData.os: object expected");
                    message.os[i] = $root.naturalcloudsyncv2.Obj.fromObject(object.os[i]);
                }
            }
            if (object.t != null)
                message.t = object.t | 0;
            if (object.i != null)
                message.i = object.i | 0;
            return message;
        };

        /**
         * Creates a plain object from an OperationData message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {naturalcloudsyncv2.OperationData} message OperationData
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        OperationData.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.arrays || options.defaults)
                object.os = [];
            if (options.defaults) {
                object.t = 0;
                object.i = 0;
            }
            if (message.os && message.os.length) {
                object.os = [];
                for (let j = 0; j < message.os.length; ++j)
                    object.os[j] = $root.naturalcloudsyncv2.Obj.toObject(message.os[j], options);
            }
            if (message.t != null && message.hasOwnProperty("t"))
                object.t = message.t;
            if (message.i != null && message.hasOwnProperty("i"))
                object.i = message.i;
            return object;
        };

        /**
         * Converts this OperationData to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.OperationData
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        OperationData.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for OperationData
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.OperationData
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        OperationData.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.OperationData";
        };

        return OperationData;
    })();

    naturalcloudsyncv2.Obj = (function() {

        /**
         * Properties of an Obj.
         * @memberof naturalcloudsyncv2
         * @interface IObj
         * @property {Array.<naturalcloudsyncv2.IField>|null} [fs] Obj fs
         * @property {number|null} [i] Obj i
         */

        /**
         * Constructs a new Obj.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an Obj.
         * @implements IObj
         * @constructor
         * @param {naturalcloudsyncv2.IObj=} [properties] Properties to set
         */
        function Obj(properties) {
            this.fs = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * Obj fs.
         * @member {Array.<naturalcloudsyncv2.IField>} fs
         * @memberof naturalcloudsyncv2.Obj
         * @instance
         */
        Obj.prototype.fs = $util.emptyArray;

        /**
         * Obj i.
         * @member {number} i
         * @memberof naturalcloudsyncv2.Obj
         * @instance
         */
        Obj.prototype.i = 0;

        /**
         * Creates a new Obj instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {naturalcloudsyncv2.IObj=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.Obj} Obj instance
         */
        Obj.create = function create(properties) {
            return new Obj(properties);
        };

        /**
         * Encodes the specified Obj message. Does not implicitly {@link naturalcloudsyncv2.Obj.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {naturalcloudsyncv2.IObj} message Obj message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Obj.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.fs != null && message.fs.length)
                for (let i = 0; i < message.fs.length; ++i)
                    $root.naturalcloudsyncv2.Field.encode(message.fs[i], writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
            if (message.i != null && Object.hasOwnProperty.call(message, "i"))
                writer.uint32(/* id 2, wireType 0 =*/16).int32(message.i);
            return writer;
        };

        /**
         * Encodes the specified Obj message, length delimited. Does not implicitly {@link naturalcloudsyncv2.Obj.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {naturalcloudsyncv2.IObj} message Obj message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Obj.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an Obj message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.Obj} Obj
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Obj.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.Obj();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        if (!(message.fs && message.fs.length))
                            message.fs = [];
                        message.fs.push($root.naturalcloudsyncv2.Field.decode(reader, reader.uint32()));
                        break;
                    }
                case 2: {
                        message.i = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an Obj message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.Obj} Obj
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Obj.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an Obj message.
         * @function verify
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        Obj.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.fs != null && message.hasOwnProperty("fs")) {
                if (!Array.isArray(message.fs))
                    return "fs: array expected";
                for (let i = 0; i < message.fs.length; ++i) {
                    let error = $root.naturalcloudsyncv2.Field.verify(message.fs[i]);
                    if (error)
                        return "fs." + error;
                }
            }
            if (message.i != null && message.hasOwnProperty("i"))
                if (!$util.isInteger(message.i))
                    return "i: integer expected";
            return null;
        };

        /**
         * Creates an Obj message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.Obj} Obj
         */
        Obj.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.Obj)
                return object;
            let message = new $root.naturalcloudsyncv2.Obj();
            if (object.fs) {
                if (!Array.isArray(object.fs))
                    throw TypeError(".naturalcloudsyncv2.Obj.fs: array expected");
                message.fs = [];
                for (let i = 0; i < object.fs.length; ++i) {
                    if (typeof object.fs[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.Obj.fs: object expected");
                    message.fs[i] = $root.naturalcloudsyncv2.Field.fromObject(object.fs[i]);
                }
            }
            if (object.i != null)
                message.i = object.i | 0;
            return message;
        };

        /**
         * Creates a plain object from an Obj message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {naturalcloudsyncv2.Obj} message Obj
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        Obj.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.arrays || options.defaults)
                object.fs = [];
            if (options.defaults)
                object.i = 0;
            if (message.fs && message.fs.length) {
                object.fs = [];
                for (let j = 0; j < message.fs.length; ++j)
                    object.fs[j] = $root.naturalcloudsyncv2.Field.toObject(message.fs[j], options);
            }
            if (message.i != null && message.hasOwnProperty("i"))
                object.i = message.i;
            return object;
        };

        /**
         * Converts this Obj to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.Obj
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        Obj.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for Obj
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.Obj
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        Obj.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.Obj";
        };

        return Obj;
    })();

    naturalcloudsyncv2.Field = (function() {

        /**
         * Properties of a Field.
         * @memberof naturalcloudsyncv2
         * @interface IField
         * @property {boolean|null} [n] Field n
         * @property {boolean|null} [bl] Field bl
         * @property {number|null} [b] Field b
         * @property {number|null} [st] Field st
         * @property {number|null} [i] Field i
         * @property {Long|null} [l] Field l
         * @property {number|null} [f] Field f
         * @property {number|null} [d] Field d
         * @property {Uint8Array|null} [ba] Field ba
         * @property {string|null} [s] Field s
         */

        /**
         * Constructs a new Field.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a Field.
         * @implements IField
         * @constructor
         * @param {naturalcloudsyncv2.IField=} [properties] Properties to set
         */
        function Field(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * Field n.
         * @member {boolean} n
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.n = false;

        /**
         * Field bl.
         * @member {boolean|null|undefined} bl
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.bl = null;

        /**
         * Field b.
         * @member {number|null|undefined} b
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.b = null;

        /**
         * Field st.
         * @member {number|null|undefined} st
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.st = null;

        /**
         * Field i.
         * @member {number|null|undefined} i
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.i = null;

        /**
         * Field l.
         * @member {Long|null|undefined} l
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.l = null;

        /**
         * Field f.
         * @member {number|null|undefined} f
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.f = null;

        /**
         * Field d.
         * @member {number|null|undefined} d
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.d = null;

        /**
         * Field ba.
         * @member {Uint8Array|null|undefined} ba
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.ba = null;

        /**
         * Field s.
         * @member {string|null|undefined} s
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Field.prototype.s = null;

        // OneOf field names bound to virtual getters and setters
        let $oneOfFields;

        /**
         * Field value.
         * @member {"bl"|"b"|"st"|"i"|"l"|"f"|"d"|"ba"|"s"|undefined} value
         * @memberof naturalcloudsyncv2.Field
         * @instance
         */
        Object.defineProperty(Field.prototype, "value", {
            get: $util.oneOfGetter($oneOfFields = ["bl", "b", "st", "i", "l", "f", "d", "ba", "s"]),
            set: $util.oneOfSetter($oneOfFields)
        });

        /**
         * Creates a new Field instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {naturalcloudsyncv2.IField=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.Field} Field instance
         */
        Field.create = function create(properties) {
            return new Field(properties);
        };

        /**
         * Encodes the specified Field message. Does not implicitly {@link naturalcloudsyncv2.Field.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {naturalcloudsyncv2.IField} message Field message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Field.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.n != null && Object.hasOwnProperty.call(message, "n"))
                writer.uint32(/* id 1, wireType 0 =*/8).bool(message.n);
            if (message.bl != null && Object.hasOwnProperty.call(message, "bl"))
                writer.uint32(/* id 2, wireType 0 =*/16).bool(message.bl);
            if (message.b != null && Object.hasOwnProperty.call(message, "b"))
                writer.uint32(/* id 3, wireType 0 =*/24).int32(message.b);
            if (message.st != null && Object.hasOwnProperty.call(message, "st"))
                writer.uint32(/* id 4, wireType 0 =*/32).int32(message.st);
            if (message.i != null && Object.hasOwnProperty.call(message, "i"))
                writer.uint32(/* id 5, wireType 0 =*/40).int32(message.i);
            if (message.l != null && Object.hasOwnProperty.call(message, "l"))
                writer.uint32(/* id 6, wireType 0 =*/48).int64(message.l);
            if (message.f != null && Object.hasOwnProperty.call(message, "f"))
                writer.uint32(/* id 7, wireType 5 =*/61).float(message.f);
            if (message.d != null && Object.hasOwnProperty.call(message, "d"))
                writer.uint32(/* id 8, wireType 1 =*/65).double(message.d);
            if (message.ba != null && Object.hasOwnProperty.call(message, "ba"))
                writer.uint32(/* id 9, wireType 2 =*/74).bytes(message.ba);
            if (message.s != null && Object.hasOwnProperty.call(message, "s"))
                writer.uint32(/* id 10, wireType 2 =*/82).string(message.s);
            return writer;
        };

        /**
         * Encodes the specified Field message, length delimited. Does not implicitly {@link naturalcloudsyncv2.Field.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {naturalcloudsyncv2.IField} message Field message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Field.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a Field message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.Field} Field
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Field.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.Field();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.n = reader.bool();
                        break;
                    }
                case 2: {
                        message.bl = reader.bool();
                        break;
                    }
                case 3: {
                        message.b = reader.int32();
                        break;
                    }
                case 4: {
                        message.st = reader.int32();
                        break;
                    }
                case 5: {
                        message.i = reader.int32();
                        break;
                    }
                case 6: {
                        message.l = reader.int64();
                        break;
                    }
                case 7: {
                        message.f = reader.float();
                        break;
                    }
                case 8: {
                        message.d = reader.double();
                        break;
                    }
                case 9: {
                        message.ba = reader.bytes();
                        break;
                    }
                case 10: {
                        message.s = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a Field message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.Field} Field
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Field.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a Field message.
         * @function verify
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        Field.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            let properties = {};
            if (message.n != null && message.hasOwnProperty("n"))
                if (typeof message.n !== "boolean")
                    return "n: boolean expected";
            if (message.bl != null && message.hasOwnProperty("bl")) {
                properties.value = 1;
                if (typeof message.bl !== "boolean")
                    return "bl: boolean expected";
            }
            if (message.b != null && message.hasOwnProperty("b")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (!$util.isInteger(message.b))
                    return "b: integer expected";
            }
            if (message.st != null && message.hasOwnProperty("st")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (!$util.isInteger(message.st))
                    return "st: integer expected";
            }
            if (message.i != null && message.hasOwnProperty("i")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (!$util.isInteger(message.i))
                    return "i: integer expected";
            }
            if (message.l != null && message.hasOwnProperty("l")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (!$util.isInteger(message.l) && !(message.l && $util.isInteger(message.l.low) && $util.isInteger(message.l.high)))
                    return "l: integer|Long expected";
            }
            if (message.f != null && message.hasOwnProperty("f")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (typeof message.f !== "number")
                    return "f: number expected";
            }
            if (message.d != null && message.hasOwnProperty("d")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (typeof message.d !== "number")
                    return "d: number expected";
            }
            if (message.ba != null && message.hasOwnProperty("ba")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (!(message.ba && typeof message.ba.length === "number" || $util.isString(message.ba)))
                    return "ba: buffer expected";
            }
            if (message.s != null && message.hasOwnProperty("s")) {
                if (properties.value === 1)
                    return "value: multiple values";
                properties.value = 1;
                if (!$util.isString(message.s))
                    return "s: string expected";
            }
            return null;
        };

        /**
         * Creates a Field message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.Field} Field
         */
        Field.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.Field)
                return object;
            let message = new $root.naturalcloudsyncv2.Field();
            if (object.n != null)
                message.n = Boolean(object.n);
            if (object.bl != null)
                message.bl = Boolean(object.bl);
            if (object.b != null)
                message.b = object.b | 0;
            if (object.st != null)
                message.st = object.st | 0;
            if (object.i != null)
                message.i = object.i | 0;
            if (object.l != null)
                if ($util.Long)
                    (message.l = $util.Long.fromValue(object.l)).unsigned = false;
                else if (typeof object.l === "string")
                    message.l = parseInt(object.l, 10);
                else if (typeof object.l === "number")
                    message.l = object.l;
                else if (typeof object.l === "object")
                    message.l = new $util.LongBits(object.l.low >>> 0, object.l.high >>> 0).toNumber();
            if (object.f != null)
                message.f = Number(object.f);
            if (object.d != null)
                message.d = Number(object.d);
            if (object.ba != null)
                if (typeof object.ba === "string")
                    $util.base64.decode(object.ba, message.ba = $util.newBuffer($util.base64.length(object.ba)), 0);
                else if (object.ba.length >= 0)
                    message.ba = object.ba;
            if (object.s != null)
                message.s = String(object.s);
            return message;
        };

        /**
         * Creates a plain object from a Field message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {naturalcloudsyncv2.Field} message Field
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        Field.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults)
                object.n = false;
            if (message.n != null && message.hasOwnProperty("n"))
                object.n = message.n;
            if (message.bl != null && message.hasOwnProperty("bl")) {
                object.bl = message.bl;
                if (options.oneofs)
                    object.value = "bl";
            }
            if (message.b != null && message.hasOwnProperty("b")) {
                object.b = message.b;
                if (options.oneofs)
                    object.value = "b";
            }
            if (message.st != null && message.hasOwnProperty("st")) {
                object.st = message.st;
                if (options.oneofs)
                    object.value = "st";
            }
            if (message.i != null && message.hasOwnProperty("i")) {
                object.i = message.i;
                if (options.oneofs)
                    object.value = "i";
            }
            if (message.l != null && message.hasOwnProperty("l")) {
                if (typeof message.l === "number")
                    object.l = options.longs === String ? String(message.l) : message.l;
                else
                    object.l = options.longs === String ? $util.Long.prototype.toString.call(message.l) : options.longs === Number ? new $util.LongBits(message.l.low >>> 0, message.l.high >>> 0).toNumber() : message.l;
                if (options.oneofs)
                    object.value = "l";
            }
            if (message.f != null && message.hasOwnProperty("f")) {
                object.f = options.json && !isFinite(message.f) ? String(message.f) : message.f;
                if (options.oneofs)
                    object.value = "f";
            }
            if (message.d != null && message.hasOwnProperty("d")) {
                object.d = options.json && !isFinite(message.d) ? String(message.d) : message.d;
                if (options.oneofs)
                    object.value = "d";
            }
            if (message.ba != null && message.hasOwnProperty("ba")) {
                object.ba = options.bytes === String ? $util.base64.encode(message.ba, 0, message.ba.length) : options.bytes === Array ? Array.prototype.slice.call(message.ba) : message.ba;
                if (options.oneofs)
                    object.value = "ba";
            }
            if (message.s != null && message.hasOwnProperty("s")) {
                object.s = message.s;
                if (options.oneofs)
                    object.value = "s";
            }
            return object;
        };

        /**
         * Converts this Field to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.Field
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        Field.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for Field
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.Field
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        Field.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.Field";
        };

        return Field;
    })();

    naturalcloudsyncv2.MessageInfo = (function() {

        /**
         * Properties of a MessageInfo.
         * @memberof naturalcloudsyncv2
         * @interface IMessageInfo
         * @property {Long|null} [id] MessageInfo id
         * @property {number|null} [type] MessageInfo type
         * @property {number|null} [subType] MessageInfo subType
         * @property {naturalcloudsyncv2.IStore|null} [opStore] MessageInfo opStore
         * @property {string|null} [traceId] MessageInfo traceId
         */

        /**
         * Constructs a new MessageInfo.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a MessageInfo.
         * @implements IMessageInfo
         * @constructor
         * @param {naturalcloudsyncv2.IMessageInfo=} [properties] Properties to set
         */
        function MessageInfo(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * MessageInfo id.
         * @member {Long} id
         * @memberof naturalcloudsyncv2.MessageInfo
         * @instance
         */
        MessageInfo.prototype.id = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * MessageInfo type.
         * @member {number} type
         * @memberof naturalcloudsyncv2.MessageInfo
         * @instance
         */
        MessageInfo.prototype.type = 0;

        /**
         * MessageInfo subType.
         * @member {number} subType
         * @memberof naturalcloudsyncv2.MessageInfo
         * @instance
         */
        MessageInfo.prototype.subType = 0;

        /**
         * MessageInfo opStore.
         * @member {naturalcloudsyncv2.IStore|null|undefined} opStore
         * @memberof naturalcloudsyncv2.MessageInfo
         * @instance
         */
        MessageInfo.prototype.opStore = null;

        /**
         * MessageInfo traceId.
         * @member {string} traceId
         * @memberof naturalcloudsyncv2.MessageInfo
         * @instance
         */
        MessageInfo.prototype.traceId = "";

        /**
         * Creates a new MessageInfo instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {naturalcloudsyncv2.IMessageInfo=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.MessageInfo} MessageInfo instance
         */
        MessageInfo.create = function create(properties) {
            return new MessageInfo(properties);
        };

        /**
         * Encodes the specified MessageInfo message. Does not implicitly {@link naturalcloudsyncv2.MessageInfo.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {naturalcloudsyncv2.IMessageInfo} message MessageInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        MessageInfo.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.id != null && Object.hasOwnProperty.call(message, "id"))
                writer.uint32(/* id 1, wireType 0 =*/8).int64(message.id);
            if (message.type != null && Object.hasOwnProperty.call(message, "type"))
                writer.uint32(/* id 2, wireType 0 =*/16).int32(message.type);
            if (message.subType != null && Object.hasOwnProperty.call(message, "subType"))
                writer.uint32(/* id 3, wireType 0 =*/24).int32(message.subType);
            if (message.opStore != null && Object.hasOwnProperty.call(message, "opStore"))
                $root.naturalcloudsyncv2.Store.encode(message.opStore, writer.uint32(/* id 4, wireType 2 =*/34).fork()).ldelim();
            if (message.traceId != null && Object.hasOwnProperty.call(message, "traceId"))
                writer.uint32(/* id 5, wireType 2 =*/42).string(message.traceId);
            return writer;
        };

        /**
         * Encodes the specified MessageInfo message, length delimited. Does not implicitly {@link naturalcloudsyncv2.MessageInfo.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {naturalcloudsyncv2.IMessageInfo} message MessageInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        MessageInfo.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a MessageInfo message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.MessageInfo} MessageInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        MessageInfo.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.MessageInfo();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.id = reader.int64();
                        break;
                    }
                case 2: {
                        message.type = reader.int32();
                        break;
                    }
                case 3: {
                        message.subType = reader.int32();
                        break;
                    }
                case 4: {
                        message.opStore = $root.naturalcloudsyncv2.Store.decode(reader, reader.uint32());
                        break;
                    }
                case 5: {
                        message.traceId = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a MessageInfo message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.MessageInfo} MessageInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        MessageInfo.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a MessageInfo message.
         * @function verify
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        MessageInfo.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.id != null && message.hasOwnProperty("id"))
                if (!$util.isInteger(message.id) && !(message.id && $util.isInteger(message.id.low) && $util.isInteger(message.id.high)))
                    return "id: integer|Long expected";
            if (message.type != null && message.hasOwnProperty("type"))
                if (!$util.isInteger(message.type))
                    return "type: integer expected";
            if (message.subType != null && message.hasOwnProperty("subType"))
                if (!$util.isInteger(message.subType))
                    return "subType: integer expected";
            if (message.opStore != null && message.hasOwnProperty("opStore")) {
                let error = $root.naturalcloudsyncv2.Store.verify(message.opStore);
                if (error)
                    return "opStore." + error;
            }
            if (message.traceId != null && message.hasOwnProperty("traceId"))
                if (!$util.isString(message.traceId))
                    return "traceId: string expected";
            return null;
        };

        /**
         * Creates a MessageInfo message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.MessageInfo} MessageInfo
         */
        MessageInfo.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.MessageInfo)
                return object;
            let message = new $root.naturalcloudsyncv2.MessageInfo();
            if (object.id != null)
                if ($util.Long)
                    (message.id = $util.Long.fromValue(object.id)).unsigned = false;
                else if (typeof object.id === "string")
                    message.id = parseInt(object.id, 10);
                else if (typeof object.id === "number")
                    message.id = object.id;
                else if (typeof object.id === "object")
                    message.id = new $util.LongBits(object.id.low >>> 0, object.id.high >>> 0).toNumber();
            if (object.type != null)
                message.type = object.type | 0;
            if (object.subType != null)
                message.subType = object.subType | 0;
            if (object.opStore != null) {
                if (typeof object.opStore !== "object")
                    throw TypeError(".naturalcloudsyncv2.MessageInfo.opStore: object expected");
                message.opStore = $root.naturalcloudsyncv2.Store.fromObject(object.opStore);
            }
            if (object.traceId != null)
                message.traceId = String(object.traceId);
            return message;
        };

        /**
         * Creates a plain object from a MessageInfo message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {naturalcloudsyncv2.MessageInfo} message MessageInfo
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        MessageInfo.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.id = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.id = options.longs === String ? "0" : 0;
                object.type = 0;
                object.subType = 0;
                object.opStore = null;
                object.traceId = "";
            }
            if (message.id != null && message.hasOwnProperty("id"))
                if (typeof message.id === "number")
                    object.id = options.longs === String ? String(message.id) : message.id;
                else
                    object.id = options.longs === String ? $util.Long.prototype.toString.call(message.id) : options.longs === Number ? new $util.LongBits(message.id.low >>> 0, message.id.high >>> 0).toNumber() : message.id;
            if (message.type != null && message.hasOwnProperty("type"))
                object.type = message.type;
            if (message.subType != null && message.hasOwnProperty("subType"))
                object.subType = message.subType;
            if (message.opStore != null && message.hasOwnProperty("opStore"))
                object.opStore = $root.naturalcloudsyncv2.Store.toObject(message.opStore, options);
            if (message.traceId != null && message.hasOwnProperty("traceId"))
                object.traceId = message.traceId;
            return object;
        };

        /**
         * Converts this MessageInfo to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.MessageInfo
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        MessageInfo.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for MessageInfo
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.MessageInfo
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        MessageInfo.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.MessageInfo";
        };

        return MessageInfo;
    })();

    naturalcloudsyncv2.Store = (function() {

        /**
         * Properties of a Store.
         * @memberof naturalcloudsyncv2
         * @interface IStore
         * @property {string|null} [storeName] Store storeName
         */

        /**
         * Constructs a new Store.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a Store.
         * @implements IStore
         * @constructor
         * @param {naturalcloudsyncv2.IStore=} [properties] Properties to set
         */
        function Store(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * Store storeName.
         * @member {string} storeName
         * @memberof naturalcloudsyncv2.Store
         * @instance
         */
        Store.prototype.storeName = "";

        /**
         * Creates a new Store instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {naturalcloudsyncv2.IStore=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.Store} Store instance
         */
        Store.create = function create(properties) {
            return new Store(properties);
        };

        /**
         * Encodes the specified Store message. Does not implicitly {@link naturalcloudsyncv2.Store.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {naturalcloudsyncv2.IStore} message Store message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Store.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.storeName != null && Object.hasOwnProperty.call(message, "storeName"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.storeName);
            return writer;
        };

        /**
         * Encodes the specified Store message, length delimited. Does not implicitly {@link naturalcloudsyncv2.Store.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {naturalcloudsyncv2.IStore} message Store message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        Store.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a Store message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.Store} Store
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Store.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.Store();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.storeName = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a Store message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.Store} Store
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        Store.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a Store message.
         * @function verify
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        Store.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.storeName != null && message.hasOwnProperty("storeName"))
                if (!$util.isString(message.storeName))
                    return "storeName: string expected";
            return null;
        };

        /**
         * Creates a Store message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.Store} Store
         */
        Store.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.Store)
                return object;
            let message = new $root.naturalcloudsyncv2.Store();
            if (object.storeName != null)
                message.storeName = String(object.storeName);
            return message;
        };

        /**
         * Creates a plain object from a Store message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {naturalcloudsyncv2.Store} message Store
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        Store.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults)
                object.storeName = "";
            if (message.storeName != null && message.hasOwnProperty("storeName"))
                object.storeName = message.storeName;
            return object;
        };

        /**
         * Converts this Store to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.Store
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        Store.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for Store
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.Store
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        Store.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.Store";
        };

        return Store;
    })();

    naturalcloudsyncv2.EncryptionInfo = (function() {

        /**
         * Properties of an EncryptionInfo.
         * @memberof naturalcloudsyncv2
         * @interface IEncryptionInfo
         * @property {number|null} [keyStatus] EncryptionInfo keyStatus
         * @property {Uint8Array|null} [firstSalt] EncryptionInfo firstSalt
         * @property {Uint8Array|null} [secondSalt] EncryptionInfo secondSalt
         * @property {Uint8Array|null} [rootToken] EncryptionInfo rootToken
         * @property {Uint8Array|null} [cipherText] EncryptionInfo cipherText
         * @property {Uint8Array|null} [oldCipherText] EncryptionInfo oldCipherText
         * @property {number|null} [keyVer] EncryptionInfo keyVer
         */

        /**
         * Constructs a new EncryptionInfo.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an EncryptionInfo.
         * @implements IEncryptionInfo
         * @constructor
         * @param {naturalcloudsyncv2.IEncryptionInfo=} [properties] Properties to set
         */
        function EncryptionInfo(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * EncryptionInfo keyStatus.
         * @member {number} keyStatus
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.keyStatus = 0;

        /**
         * EncryptionInfo firstSalt.
         * @member {Uint8Array} firstSalt
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.firstSalt = $util.newBuffer([]);

        /**
         * EncryptionInfo secondSalt.
         * @member {Uint8Array} secondSalt
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.secondSalt = $util.newBuffer([]);

        /**
         * EncryptionInfo rootToken.
         * @member {Uint8Array} rootToken
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.rootToken = $util.newBuffer([]);

        /**
         * EncryptionInfo cipherText.
         * @member {Uint8Array} cipherText
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.cipherText = $util.newBuffer([]);

        /**
         * EncryptionInfo oldCipherText.
         * @member {Uint8Array} oldCipherText
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.oldCipherText = $util.newBuffer([]);

        /**
         * EncryptionInfo keyVer.
         * @member {number} keyVer
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         */
        EncryptionInfo.prototype.keyVer = 0;

        /**
         * Creates a new EncryptionInfo instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {naturalcloudsyncv2.IEncryptionInfo=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.EncryptionInfo} EncryptionInfo instance
         */
        EncryptionInfo.create = function create(properties) {
            return new EncryptionInfo(properties);
        };

        /**
         * Encodes the specified EncryptionInfo message. Does not implicitly {@link naturalcloudsyncv2.EncryptionInfo.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {naturalcloudsyncv2.IEncryptionInfo} message EncryptionInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        EncryptionInfo.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.keyStatus != null && Object.hasOwnProperty.call(message, "keyStatus"))
                writer.uint32(/* id 1, wireType 0 =*/8).int32(message.keyStatus);
            if (message.firstSalt != null && Object.hasOwnProperty.call(message, "firstSalt"))
                writer.uint32(/* id 2, wireType 2 =*/18).bytes(message.firstSalt);
            if (message.secondSalt != null && Object.hasOwnProperty.call(message, "secondSalt"))
                writer.uint32(/* id 3, wireType 2 =*/26).bytes(message.secondSalt);
            if (message.rootToken != null && Object.hasOwnProperty.call(message, "rootToken"))
                writer.uint32(/* id 4, wireType 2 =*/34).bytes(message.rootToken);
            if (message.cipherText != null && Object.hasOwnProperty.call(message, "cipherText"))
                writer.uint32(/* id 5, wireType 2 =*/42).bytes(message.cipherText);
            if (message.oldCipherText != null && Object.hasOwnProperty.call(message, "oldCipherText"))
                writer.uint32(/* id 6, wireType 2 =*/50).bytes(message.oldCipherText);
            if (message.keyVer != null && Object.hasOwnProperty.call(message, "keyVer"))
                writer.uint32(/* id 7, wireType 0 =*/56).int32(message.keyVer);
            return writer;
        };

        /**
         * Encodes the specified EncryptionInfo message, length delimited. Does not implicitly {@link naturalcloudsyncv2.EncryptionInfo.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {naturalcloudsyncv2.IEncryptionInfo} message EncryptionInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        EncryptionInfo.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an EncryptionInfo message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.EncryptionInfo} EncryptionInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        EncryptionInfo.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.EncryptionInfo();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.keyStatus = reader.int32();
                        break;
                    }
                case 2: {
                        message.firstSalt = reader.bytes();
                        break;
                    }
                case 3: {
                        message.secondSalt = reader.bytes();
                        break;
                    }
                case 4: {
                        message.rootToken = reader.bytes();
                        break;
                    }
                case 5: {
                        message.cipherText = reader.bytes();
                        break;
                    }
                case 6: {
                        message.oldCipherText = reader.bytes();
                        break;
                    }
                case 7: {
                        message.keyVer = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an EncryptionInfo message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.EncryptionInfo} EncryptionInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        EncryptionInfo.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an EncryptionInfo message.
         * @function verify
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        EncryptionInfo.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.keyStatus != null && message.hasOwnProperty("keyStatus"))
                if (!$util.isInteger(message.keyStatus))
                    return "keyStatus: integer expected";
            if (message.firstSalt != null && message.hasOwnProperty("firstSalt"))
                if (!(message.firstSalt && typeof message.firstSalt.length === "number" || $util.isString(message.firstSalt)))
                    return "firstSalt: buffer expected";
            if (message.secondSalt != null && message.hasOwnProperty("secondSalt"))
                if (!(message.secondSalt && typeof message.secondSalt.length === "number" || $util.isString(message.secondSalt)))
                    return "secondSalt: buffer expected";
            if (message.rootToken != null && message.hasOwnProperty("rootToken"))
                if (!(message.rootToken && typeof message.rootToken.length === "number" || $util.isString(message.rootToken)))
                    return "rootToken: buffer expected";
            if (message.cipherText != null && message.hasOwnProperty("cipherText"))
                if (!(message.cipherText && typeof message.cipherText.length === "number" || $util.isString(message.cipherText)))
                    return "cipherText: buffer expected";
            if (message.oldCipherText != null && message.hasOwnProperty("oldCipherText"))
                if (!(message.oldCipherText && typeof message.oldCipherText.length === "number" || $util.isString(message.oldCipherText)))
                    return "oldCipherText: buffer expected";
            if (message.keyVer != null && message.hasOwnProperty("keyVer"))
                if (!$util.isInteger(message.keyVer))
                    return "keyVer: integer expected";
            return null;
        };

        /**
         * Creates an EncryptionInfo message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.EncryptionInfo} EncryptionInfo
         */
        EncryptionInfo.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.EncryptionInfo)
                return object;
            let message = new $root.naturalcloudsyncv2.EncryptionInfo();
            if (object.keyStatus != null)
                message.keyStatus = object.keyStatus | 0;
            if (object.firstSalt != null)
                if (typeof object.firstSalt === "string")
                    $util.base64.decode(object.firstSalt, message.firstSalt = $util.newBuffer($util.base64.length(object.firstSalt)), 0);
                else if (object.firstSalt.length >= 0)
                    message.firstSalt = object.firstSalt;
            if (object.secondSalt != null)
                if (typeof object.secondSalt === "string")
                    $util.base64.decode(object.secondSalt, message.secondSalt = $util.newBuffer($util.base64.length(object.secondSalt)), 0);
                else if (object.secondSalt.length >= 0)
                    message.secondSalt = object.secondSalt;
            if (object.rootToken != null)
                if (typeof object.rootToken === "string")
                    $util.base64.decode(object.rootToken, message.rootToken = $util.newBuffer($util.base64.length(object.rootToken)), 0);
                else if (object.rootToken.length >= 0)
                    message.rootToken = object.rootToken;
            if (object.cipherText != null)
                if (typeof object.cipherText === "string")
                    $util.base64.decode(object.cipherText, message.cipherText = $util.newBuffer($util.base64.length(object.cipherText)), 0);
                else if (object.cipherText.length >= 0)
                    message.cipherText = object.cipherText;
            if (object.oldCipherText != null)
                if (typeof object.oldCipherText === "string")
                    $util.base64.decode(object.oldCipherText, message.oldCipherText = $util.newBuffer($util.base64.length(object.oldCipherText)), 0);
                else if (object.oldCipherText.length >= 0)
                    message.oldCipherText = object.oldCipherText;
            if (object.keyVer != null)
                message.keyVer = object.keyVer | 0;
            return message;
        };

        /**
         * Creates a plain object from an EncryptionInfo message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {naturalcloudsyncv2.EncryptionInfo} message EncryptionInfo
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        EncryptionInfo.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.keyStatus = 0;
                if (options.bytes === String)
                    object.firstSalt = "";
                else {
                    object.firstSalt = [];
                    if (options.bytes !== Array)
                        object.firstSalt = $util.newBuffer(object.firstSalt);
                }
                if (options.bytes === String)
                    object.secondSalt = "";
                else {
                    object.secondSalt = [];
                    if (options.bytes !== Array)
                        object.secondSalt = $util.newBuffer(object.secondSalt);
                }
                if (options.bytes === String)
                    object.rootToken = "";
                else {
                    object.rootToken = [];
                    if (options.bytes !== Array)
                        object.rootToken = $util.newBuffer(object.rootToken);
                }
                if (options.bytes === String)
                    object.cipherText = "";
                else {
                    object.cipherText = [];
                    if (options.bytes !== Array)
                        object.cipherText = $util.newBuffer(object.cipherText);
                }
                if (options.bytes === String)
                    object.oldCipherText = "";
                else {
                    object.oldCipherText = [];
                    if (options.bytes !== Array)
                        object.oldCipherText = $util.newBuffer(object.oldCipherText);
                }
                object.keyVer = 0;
            }
            if (message.keyStatus != null && message.hasOwnProperty("keyStatus"))
                object.keyStatus = message.keyStatus;
            if (message.firstSalt != null && message.hasOwnProperty("firstSalt"))
                object.firstSalt = options.bytes === String ? $util.base64.encode(message.firstSalt, 0, message.firstSalt.length) : options.bytes === Array ? Array.prototype.slice.call(message.firstSalt) : message.firstSalt;
            if (message.secondSalt != null && message.hasOwnProperty("secondSalt"))
                object.secondSalt = options.bytes === String ? $util.base64.encode(message.secondSalt, 0, message.secondSalt.length) : options.bytes === Array ? Array.prototype.slice.call(message.secondSalt) : message.secondSalt;
            if (message.rootToken != null && message.hasOwnProperty("rootToken"))
                object.rootToken = options.bytes === String ? $util.base64.encode(message.rootToken, 0, message.rootToken.length) : options.bytes === Array ? Array.prototype.slice.call(message.rootToken) : message.rootToken;
            if (message.cipherText != null && message.hasOwnProperty("cipherText"))
                object.cipherText = options.bytes === String ? $util.base64.encode(message.cipherText, 0, message.cipherText.length) : options.bytes === Array ? Array.prototype.slice.call(message.cipherText) : message.cipherText;
            if (message.oldCipherText != null && message.hasOwnProperty("oldCipherText"))
                object.oldCipherText = options.bytes === String ? $util.base64.encode(message.oldCipherText, 0, message.oldCipherText.length) : options.bytes === Array ? Array.prototype.slice.call(message.oldCipherText) : message.oldCipherText;
            if (message.keyVer != null && message.hasOwnProperty("keyVer"))
                object.keyVer = message.keyVer;
            return object;
        };

        /**
         * Converts this EncryptionInfo to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        EncryptionInfo.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for EncryptionInfo
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.EncryptionInfo
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        EncryptionInfo.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.EncryptionInfo";
        };

        return EncryptionInfo;
    })();

    naturalcloudsyncv2.SyncRequestMessage = (function() {

        /**
         * Properties of a SyncRequestMessage.
         * @memberof naturalcloudsyncv2
         * @interface ISyncRequestMessage
         * @property {naturalcloudsyncv2.IMessageInfo|null} [msgInfo] SyncRequestMessage msgInfo
         * @property {naturalcloudsyncv2.IClientInfo|null} [clientInfo] SyncRequestMessage clientInfo
         * @property {Array.<naturalcloudsyncv2.ISchema>|null} [schemas] SyncRequestMessage schemas
         * @property {Array.<naturalcloudsyncv2.IOperationData>|null} [opData] SyncRequestMessage opData
         * @property {naturalcloudsyncv2.IQueryRequestMessage|null} [queryReqMsg] SyncRequestMessage queryReqMsg
         * @property {Array.<naturalcloudsyncv2.ISubscribeRequestMessage>|null} [subReqMsg] SyncRequestMessage subReqMsg
         * @property {Array.<naturalcloudsyncv2.IUnsubscribeRequestMessage>|null} [unSubReqMsg] SyncRequestMessage unSubReqMsg
         * @property {Array.<naturalcloudsyncv2.IEncryptionInfo>|null} [enReqInfo] SyncRequestMessage enReqInfo
         */

        /**
         * Constructs a new SyncRequestMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a SyncRequestMessage.
         * @implements ISyncRequestMessage
         * @constructor
         * @param {naturalcloudsyncv2.ISyncRequestMessage=} [properties] Properties to set
         */
        function SyncRequestMessage(properties) {
            this.schemas = [];
            this.opData = [];
            this.subReqMsg = [];
            this.unSubReqMsg = [];
            this.enReqInfo = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * SyncRequestMessage msgInfo.
         * @member {naturalcloudsyncv2.IMessageInfo|null|undefined} msgInfo
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.msgInfo = null;

        /**
         * SyncRequestMessage clientInfo.
         * @member {naturalcloudsyncv2.IClientInfo|null|undefined} clientInfo
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.clientInfo = null;

        /**
         * SyncRequestMessage schemas.
         * @member {Array.<naturalcloudsyncv2.ISchema>} schemas
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.schemas = $util.emptyArray;

        /**
         * SyncRequestMessage opData.
         * @member {Array.<naturalcloudsyncv2.IOperationData>} opData
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.opData = $util.emptyArray;

        /**
         * SyncRequestMessage queryReqMsg.
         * @member {naturalcloudsyncv2.IQueryRequestMessage|null|undefined} queryReqMsg
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.queryReqMsg = null;

        /**
         * SyncRequestMessage subReqMsg.
         * @member {Array.<naturalcloudsyncv2.ISubscribeRequestMessage>} subReqMsg
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.subReqMsg = $util.emptyArray;

        /**
         * SyncRequestMessage unSubReqMsg.
         * @member {Array.<naturalcloudsyncv2.IUnsubscribeRequestMessage>} unSubReqMsg
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.unSubReqMsg = $util.emptyArray;

        /**
         * SyncRequestMessage enReqInfo.
         * @member {Array.<naturalcloudsyncv2.IEncryptionInfo>} enReqInfo
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         */
        SyncRequestMessage.prototype.enReqInfo = $util.emptyArray;

        /**
         * Creates a new SyncRequestMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {naturalcloudsyncv2.ISyncRequestMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.SyncRequestMessage} SyncRequestMessage instance
         */
        SyncRequestMessage.create = function create(properties) {
            return new SyncRequestMessage(properties);
        };

        /**
         * Encodes the specified SyncRequestMessage message. Does not implicitly {@link naturalcloudsyncv2.SyncRequestMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {naturalcloudsyncv2.ISyncRequestMessage} message SyncRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SyncRequestMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.msgInfo != null && Object.hasOwnProperty.call(message, "msgInfo"))
                $root.naturalcloudsyncv2.MessageInfo.encode(message.msgInfo, writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
            if (message.clientInfo != null && Object.hasOwnProperty.call(message, "clientInfo"))
                $root.naturalcloudsyncv2.ClientInfo.encode(message.clientInfo, writer.uint32(/* id 2, wireType 2 =*/18).fork()).ldelim();
            if (message.schemas != null && message.schemas.length)
                for (let i = 0; i < message.schemas.length; ++i)
                    $root.naturalcloudsyncv2.Schema.encode(message.schemas[i], writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
            if (message.opData != null && message.opData.length)
                for (let i = 0; i < message.opData.length; ++i)
                    $root.naturalcloudsyncv2.OperationData.encode(message.opData[i], writer.uint32(/* id 4, wireType 2 =*/34).fork()).ldelim();
            if (message.queryReqMsg != null && Object.hasOwnProperty.call(message, "queryReqMsg"))
                $root.naturalcloudsyncv2.QueryRequestMessage.encode(message.queryReqMsg, writer.uint32(/* id 5, wireType 2 =*/42).fork()).ldelim();
            if (message.subReqMsg != null && message.subReqMsg.length)
                for (let i = 0; i < message.subReqMsg.length; ++i)
                    $root.naturalcloudsyncv2.SubscribeRequestMessage.encode(message.subReqMsg[i], writer.uint32(/* id 6, wireType 2 =*/50).fork()).ldelim();
            if (message.unSubReqMsg != null && message.unSubReqMsg.length)
                for (let i = 0; i < message.unSubReqMsg.length; ++i)
                    $root.naturalcloudsyncv2.UnsubscribeRequestMessage.encode(message.unSubReqMsg[i], writer.uint32(/* id 7, wireType 2 =*/58).fork()).ldelim();
            if (message.enReqInfo != null && message.enReqInfo.length)
                for (let i = 0; i < message.enReqInfo.length; ++i)
                    $root.naturalcloudsyncv2.EncryptionInfo.encode(message.enReqInfo[i], writer.uint32(/* id 8, wireType 2 =*/66).fork()).ldelim();
            return writer;
        };

        /**
         * Encodes the specified SyncRequestMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.SyncRequestMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {naturalcloudsyncv2.ISyncRequestMessage} message SyncRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SyncRequestMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a SyncRequestMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.SyncRequestMessage} SyncRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SyncRequestMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.SyncRequestMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.msgInfo = $root.naturalcloudsyncv2.MessageInfo.decode(reader, reader.uint32());
                        break;
                    }
                case 2: {
                        message.clientInfo = $root.naturalcloudsyncv2.ClientInfo.decode(reader, reader.uint32());
                        break;
                    }
                case 3: {
                        if (!(message.schemas && message.schemas.length))
                            message.schemas = [];
                        message.schemas.push($root.naturalcloudsyncv2.Schema.decode(reader, reader.uint32()));
                        break;
                    }
                case 4: {
                        if (!(message.opData && message.opData.length))
                            message.opData = [];
                        message.opData.push($root.naturalcloudsyncv2.OperationData.decode(reader, reader.uint32()));
                        break;
                    }
                case 5: {
                        message.queryReqMsg = $root.naturalcloudsyncv2.QueryRequestMessage.decode(reader, reader.uint32());
                        break;
                    }
                case 6: {
                        if (!(message.subReqMsg && message.subReqMsg.length))
                            message.subReqMsg = [];
                        message.subReqMsg.push($root.naturalcloudsyncv2.SubscribeRequestMessage.decode(reader, reader.uint32()));
                        break;
                    }
                case 7: {
                        if (!(message.unSubReqMsg && message.unSubReqMsg.length))
                            message.unSubReqMsg = [];
                        message.unSubReqMsg.push($root.naturalcloudsyncv2.UnsubscribeRequestMessage.decode(reader, reader.uint32()));
                        break;
                    }
                case 8: {
                        if (!(message.enReqInfo && message.enReqInfo.length))
                            message.enReqInfo = [];
                        message.enReqInfo.push($root.naturalcloudsyncv2.EncryptionInfo.decode(reader, reader.uint32()));
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a SyncRequestMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.SyncRequestMessage} SyncRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SyncRequestMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a SyncRequestMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        SyncRequestMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.msgInfo != null && message.hasOwnProperty("msgInfo")) {
                let error = $root.naturalcloudsyncv2.MessageInfo.verify(message.msgInfo);
                if (error)
                    return "msgInfo." + error;
            }
            if (message.clientInfo != null && message.hasOwnProperty("clientInfo")) {
                let error = $root.naturalcloudsyncv2.ClientInfo.verify(message.clientInfo);
                if (error)
                    return "clientInfo." + error;
            }
            if (message.schemas != null && message.hasOwnProperty("schemas")) {
                if (!Array.isArray(message.schemas))
                    return "schemas: array expected";
                for (let i = 0; i < message.schemas.length; ++i) {
                    let error = $root.naturalcloudsyncv2.Schema.verify(message.schemas[i]);
                    if (error)
                        return "schemas." + error;
                }
            }
            if (message.opData != null && message.hasOwnProperty("opData")) {
                if (!Array.isArray(message.opData))
                    return "opData: array expected";
                for (let i = 0; i < message.opData.length; ++i) {
                    let error = $root.naturalcloudsyncv2.OperationData.verify(message.opData[i]);
                    if (error)
                        return "opData." + error;
                }
            }
            if (message.queryReqMsg != null && message.hasOwnProperty("queryReqMsg")) {
                let error = $root.naturalcloudsyncv2.QueryRequestMessage.verify(message.queryReqMsg);
                if (error)
                    return "queryReqMsg." + error;
            }
            if (message.subReqMsg != null && message.hasOwnProperty("subReqMsg")) {
                if (!Array.isArray(message.subReqMsg))
                    return "subReqMsg: array expected";
                for (let i = 0; i < message.subReqMsg.length; ++i) {
                    let error = $root.naturalcloudsyncv2.SubscribeRequestMessage.verify(message.subReqMsg[i]);
                    if (error)
                        return "subReqMsg." + error;
                }
            }
            if (message.unSubReqMsg != null && message.hasOwnProperty("unSubReqMsg")) {
                if (!Array.isArray(message.unSubReqMsg))
                    return "unSubReqMsg: array expected";
                for (let i = 0; i < message.unSubReqMsg.length; ++i) {
                    let error = $root.naturalcloudsyncv2.UnsubscribeRequestMessage.verify(message.unSubReqMsg[i]);
                    if (error)
                        return "unSubReqMsg." + error;
                }
            }
            if (message.enReqInfo != null && message.hasOwnProperty("enReqInfo")) {
                if (!Array.isArray(message.enReqInfo))
                    return "enReqInfo: array expected";
                for (let i = 0; i < message.enReqInfo.length; ++i) {
                    let error = $root.naturalcloudsyncv2.EncryptionInfo.verify(message.enReqInfo[i]);
                    if (error)
                        return "enReqInfo." + error;
                }
            }
            return null;
        };

        /**
         * Creates a SyncRequestMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.SyncRequestMessage} SyncRequestMessage
         */
        SyncRequestMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.SyncRequestMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.SyncRequestMessage();
            if (object.msgInfo != null) {
                if (typeof object.msgInfo !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.msgInfo: object expected");
                message.msgInfo = $root.naturalcloudsyncv2.MessageInfo.fromObject(object.msgInfo);
            }
            if (object.clientInfo != null) {
                if (typeof object.clientInfo !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.clientInfo: object expected");
                message.clientInfo = $root.naturalcloudsyncv2.ClientInfo.fromObject(object.clientInfo);
            }
            if (object.schemas) {
                if (!Array.isArray(object.schemas))
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.schemas: array expected");
                message.schemas = [];
                for (let i = 0; i < object.schemas.length; ++i) {
                    if (typeof object.schemas[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.schemas: object expected");
                    message.schemas[i] = $root.naturalcloudsyncv2.Schema.fromObject(object.schemas[i]);
                }
            }
            if (object.opData) {
                if (!Array.isArray(object.opData))
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.opData: array expected");
                message.opData = [];
                for (let i = 0; i < object.opData.length; ++i) {
                    if (typeof object.opData[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.opData: object expected");
                    message.opData[i] = $root.naturalcloudsyncv2.OperationData.fromObject(object.opData[i]);
                }
            }
            if (object.queryReqMsg != null) {
                if (typeof object.queryReqMsg !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.queryReqMsg: object expected");
                message.queryReqMsg = $root.naturalcloudsyncv2.QueryRequestMessage.fromObject(object.queryReqMsg);
            }
            if (object.subReqMsg) {
                if (!Array.isArray(object.subReqMsg))
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.subReqMsg: array expected");
                message.subReqMsg = [];
                for (let i = 0; i < object.subReqMsg.length; ++i) {
                    if (typeof object.subReqMsg[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.subReqMsg: object expected");
                    message.subReqMsg[i] = $root.naturalcloudsyncv2.SubscribeRequestMessage.fromObject(object.subReqMsg[i]);
                }
            }
            if (object.unSubReqMsg) {
                if (!Array.isArray(object.unSubReqMsg))
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.unSubReqMsg: array expected");
                message.unSubReqMsg = [];
                for (let i = 0; i < object.unSubReqMsg.length; ++i) {
                    if (typeof object.unSubReqMsg[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.unSubReqMsg: object expected");
                    message.unSubReqMsg[i] = $root.naturalcloudsyncv2.UnsubscribeRequestMessage.fromObject(object.unSubReqMsg[i]);
                }
            }
            if (object.enReqInfo) {
                if (!Array.isArray(object.enReqInfo))
                    throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.enReqInfo: array expected");
                message.enReqInfo = [];
                for (let i = 0; i < object.enReqInfo.length; ++i) {
                    if (typeof object.enReqInfo[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncRequestMessage.enReqInfo: object expected");
                    message.enReqInfo[i] = $root.naturalcloudsyncv2.EncryptionInfo.fromObject(object.enReqInfo[i]);
                }
            }
            return message;
        };

        /**
         * Creates a plain object from a SyncRequestMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {naturalcloudsyncv2.SyncRequestMessage} message SyncRequestMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        SyncRequestMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.arrays || options.defaults) {
                object.schemas = [];
                object.opData = [];
                object.subReqMsg = [];
                object.unSubReqMsg = [];
                object.enReqInfo = [];
            }
            if (options.defaults) {
                object.msgInfo = null;
                object.clientInfo = null;
                object.queryReqMsg = null;
            }
            if (message.msgInfo != null && message.hasOwnProperty("msgInfo"))
                object.msgInfo = $root.naturalcloudsyncv2.MessageInfo.toObject(message.msgInfo, options);
            if (message.clientInfo != null && message.hasOwnProperty("clientInfo"))
                object.clientInfo = $root.naturalcloudsyncv2.ClientInfo.toObject(message.clientInfo, options);
            if (message.schemas && message.schemas.length) {
                object.schemas = [];
                for (let j = 0; j < message.schemas.length; ++j)
                    object.schemas[j] = $root.naturalcloudsyncv2.Schema.toObject(message.schemas[j], options);
            }
            if (message.opData && message.opData.length) {
                object.opData = [];
                for (let j = 0; j < message.opData.length; ++j)
                    object.opData[j] = $root.naturalcloudsyncv2.OperationData.toObject(message.opData[j], options);
            }
            if (message.queryReqMsg != null && message.hasOwnProperty("queryReqMsg"))
                object.queryReqMsg = $root.naturalcloudsyncv2.QueryRequestMessage.toObject(message.queryReqMsg, options);
            if (message.subReqMsg && message.subReqMsg.length) {
                object.subReqMsg = [];
                for (let j = 0; j < message.subReqMsg.length; ++j)
                    object.subReqMsg[j] = $root.naturalcloudsyncv2.SubscribeRequestMessage.toObject(message.subReqMsg[j], options);
            }
            if (message.unSubReqMsg && message.unSubReqMsg.length) {
                object.unSubReqMsg = [];
                for (let j = 0; j < message.unSubReqMsg.length; ++j)
                    object.unSubReqMsg[j] = $root.naturalcloudsyncv2.UnsubscribeRequestMessage.toObject(message.unSubReqMsg[j], options);
            }
            if (message.enReqInfo && message.enReqInfo.length) {
                object.enReqInfo = [];
                for (let j = 0; j < message.enReqInfo.length; ++j)
                    object.enReqInfo[j] = $root.naturalcloudsyncv2.EncryptionInfo.toObject(message.enReqInfo[j], options);
            }
            return object;
        };

        /**
         * Converts this SyncRequestMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        SyncRequestMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for SyncRequestMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.SyncRequestMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        SyncRequestMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.SyncRequestMessage";
        };

        return SyncRequestMessage;
    })();

    naturalcloudsyncv2.ClientInfo = (function() {

        /**
         * Properties of a ClientInfo.
         * @memberof naturalcloudsyncv2
         * @interface IClientInfo
         * @property {string|null} [uid] ClientInfo uid
         * @property {string|null} [pid] ClientInfo pid
         * @property {string|null} [cid] ClientInfo cid
         * @property {string|null} [aid] ClientInfo aid
         * @property {Long|null} [appVer] ClientInfo appVer
         * @property {number|null} [msgVer] ClientInfo msgVer
         * @property {number|null} [enVer] ClientInfo enVer
         */

        /**
         * Constructs a new ClientInfo.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a ClientInfo.
         * @implements IClientInfo
         * @constructor
         * @param {naturalcloudsyncv2.IClientInfo=} [properties] Properties to set
         */
        function ClientInfo(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * ClientInfo uid.
         * @member {string} uid
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.uid = "";

        /**
         * ClientInfo pid.
         * @member {string} pid
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.pid = "";

        /**
         * ClientInfo cid.
         * @member {string} cid
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.cid = "";

        /**
         * ClientInfo aid.
         * @member {string} aid
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.aid = "";

        /**
         * ClientInfo appVer.
         * @member {Long} appVer
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.appVer = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * ClientInfo msgVer.
         * @member {number} msgVer
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.msgVer = 0;

        /**
         * ClientInfo enVer.
         * @member {number} enVer
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         */
        ClientInfo.prototype.enVer = 0;

        /**
         * Creates a new ClientInfo instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {naturalcloudsyncv2.IClientInfo=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.ClientInfo} ClientInfo instance
         */
        ClientInfo.create = function create(properties) {
            return new ClientInfo(properties);
        };

        /**
         * Encodes the specified ClientInfo message. Does not implicitly {@link naturalcloudsyncv2.ClientInfo.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {naturalcloudsyncv2.IClientInfo} message ClientInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ClientInfo.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.uid != null && Object.hasOwnProperty.call(message, "uid"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.uid);
            if (message.pid != null && Object.hasOwnProperty.call(message, "pid"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.pid);
            if (message.cid != null && Object.hasOwnProperty.call(message, "cid"))
                writer.uint32(/* id 3, wireType 2 =*/26).string(message.cid);
            if (message.aid != null && Object.hasOwnProperty.call(message, "aid"))
                writer.uint32(/* id 4, wireType 2 =*/34).string(message.aid);
            if (message.appVer != null && Object.hasOwnProperty.call(message, "appVer"))
                writer.uint32(/* id 5, wireType 0 =*/40).int64(message.appVer);
            if (message.msgVer != null && Object.hasOwnProperty.call(message, "msgVer"))
                writer.uint32(/* id 6, wireType 0 =*/48).int32(message.msgVer);
            if (message.enVer != null && Object.hasOwnProperty.call(message, "enVer"))
                writer.uint32(/* id 7, wireType 0 =*/56).int32(message.enVer);
            return writer;
        };

        /**
         * Encodes the specified ClientInfo message, length delimited. Does not implicitly {@link naturalcloudsyncv2.ClientInfo.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {naturalcloudsyncv2.IClientInfo} message ClientInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ClientInfo.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a ClientInfo message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.ClientInfo} ClientInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ClientInfo.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.ClientInfo();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.uid = reader.string();
                        break;
                    }
                case 2: {
                        message.pid = reader.string();
                        break;
                    }
                case 3: {
                        message.cid = reader.string();
                        break;
                    }
                case 4: {
                        message.aid = reader.string();
                        break;
                    }
                case 5: {
                        message.appVer = reader.int64();
                        break;
                    }
                case 6: {
                        message.msgVer = reader.int32();
                        break;
                    }
                case 7: {
                        message.enVer = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a ClientInfo message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.ClientInfo} ClientInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ClientInfo.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a ClientInfo message.
         * @function verify
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        ClientInfo.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.uid != null && message.hasOwnProperty("uid"))
                if (!$util.isString(message.uid))
                    return "uid: string expected";
            if (message.pid != null && message.hasOwnProperty("pid"))
                if (!$util.isString(message.pid))
                    return "pid: string expected";
            if (message.cid != null && message.hasOwnProperty("cid"))
                if (!$util.isString(message.cid))
                    return "cid: string expected";
            if (message.aid != null && message.hasOwnProperty("aid"))
                if (!$util.isString(message.aid))
                    return "aid: string expected";
            if (message.appVer != null && message.hasOwnProperty("appVer"))
                if (!$util.isInteger(message.appVer) && !(message.appVer && $util.isInteger(message.appVer.low) && $util.isInteger(message.appVer.high)))
                    return "appVer: integer|Long expected";
            if (message.msgVer != null && message.hasOwnProperty("msgVer"))
                if (!$util.isInteger(message.msgVer))
                    return "msgVer: integer expected";
            if (message.enVer != null && message.hasOwnProperty("enVer"))
                if (!$util.isInteger(message.enVer))
                    return "enVer: integer expected";
            return null;
        };

        /**
         * Creates a ClientInfo message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.ClientInfo} ClientInfo
         */
        ClientInfo.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.ClientInfo)
                return object;
            let message = new $root.naturalcloudsyncv2.ClientInfo();
            if (object.uid != null)
                message.uid = String(object.uid);
            if (object.pid != null)
                message.pid = String(object.pid);
            if (object.cid != null)
                message.cid = String(object.cid);
            if (object.aid != null)
                message.aid = String(object.aid);
            if (object.appVer != null)
                if ($util.Long)
                    (message.appVer = $util.Long.fromValue(object.appVer)).unsigned = false;
                else if (typeof object.appVer === "string")
                    message.appVer = parseInt(object.appVer, 10);
                else if (typeof object.appVer === "number")
                    message.appVer = object.appVer;
                else if (typeof object.appVer === "object")
                    message.appVer = new $util.LongBits(object.appVer.low >>> 0, object.appVer.high >>> 0).toNumber();
            if (object.msgVer != null)
                message.msgVer = object.msgVer | 0;
            if (object.enVer != null)
                message.enVer = object.enVer | 0;
            return message;
        };

        /**
         * Creates a plain object from a ClientInfo message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {naturalcloudsyncv2.ClientInfo} message ClientInfo
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        ClientInfo.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.uid = "";
                object.pid = "";
                object.cid = "";
                object.aid = "";
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.appVer = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.appVer = options.longs === String ? "0" : 0;
                object.msgVer = 0;
                object.enVer = 0;
            }
            if (message.uid != null && message.hasOwnProperty("uid"))
                object.uid = message.uid;
            if (message.pid != null && message.hasOwnProperty("pid"))
                object.pid = message.pid;
            if (message.cid != null && message.hasOwnProperty("cid"))
                object.cid = message.cid;
            if (message.aid != null && message.hasOwnProperty("aid"))
                object.aid = message.aid;
            if (message.appVer != null && message.hasOwnProperty("appVer"))
                if (typeof message.appVer === "number")
                    object.appVer = options.longs === String ? String(message.appVer) : message.appVer;
                else
                    object.appVer = options.longs === String ? $util.Long.prototype.toString.call(message.appVer) : options.longs === Number ? new $util.LongBits(message.appVer.low >>> 0, message.appVer.high >>> 0).toNumber() : message.appVer;
            if (message.msgVer != null && message.hasOwnProperty("msgVer"))
                object.msgVer = message.msgVer;
            if (message.enVer != null && message.hasOwnProperty("enVer"))
                object.enVer = message.enVer;
            return object;
        };

        /**
         * Converts this ClientInfo to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.ClientInfo
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        ClientInfo.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for ClientInfo
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.ClientInfo
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        ClientInfo.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.ClientInfo";
        };

        return ClientInfo;
    })();

    naturalcloudsyncv2.QueryRequestMessage = (function() {

        /**
         * Properties of a QueryRequestMessage.
         * @memberof naturalcloudsyncv2
         * @interface IQueryRequestMessage
         * @property {number|null} [queryType] QueryRequestMessage queryType
         * @property {string|null} [queryTable] QueryRequestMessage queryTable
         * @property {string|null} [queryCond] QueryRequestMessage queryCond
         */

        /**
         * Constructs a new QueryRequestMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a QueryRequestMessage.
         * @implements IQueryRequestMessage
         * @constructor
         * @param {naturalcloudsyncv2.IQueryRequestMessage=} [properties] Properties to set
         */
        function QueryRequestMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * QueryRequestMessage queryType.
         * @member {number} queryType
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @instance
         */
        QueryRequestMessage.prototype.queryType = 0;

        /**
         * QueryRequestMessage queryTable.
         * @member {string} queryTable
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @instance
         */
        QueryRequestMessage.prototype.queryTable = "";

        /**
         * QueryRequestMessage queryCond.
         * @member {string} queryCond
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @instance
         */
        QueryRequestMessage.prototype.queryCond = "";

        /**
         * Creates a new QueryRequestMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {naturalcloudsyncv2.IQueryRequestMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.QueryRequestMessage} QueryRequestMessage instance
         */
        QueryRequestMessage.create = function create(properties) {
            return new QueryRequestMessage(properties);
        };

        /**
         * Encodes the specified QueryRequestMessage message. Does not implicitly {@link naturalcloudsyncv2.QueryRequestMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {naturalcloudsyncv2.IQueryRequestMessage} message QueryRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        QueryRequestMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.queryType != null && Object.hasOwnProperty.call(message, "queryType"))
                writer.uint32(/* id 1, wireType 0 =*/8).int32(message.queryType);
            if (message.queryTable != null && Object.hasOwnProperty.call(message, "queryTable"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.queryTable);
            if (message.queryCond != null && Object.hasOwnProperty.call(message, "queryCond"))
                writer.uint32(/* id 3, wireType 2 =*/26).string(message.queryCond);
            return writer;
        };

        /**
         * Encodes the specified QueryRequestMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.QueryRequestMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {naturalcloudsyncv2.IQueryRequestMessage} message QueryRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        QueryRequestMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a QueryRequestMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.QueryRequestMessage} QueryRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        QueryRequestMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.QueryRequestMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.queryType = reader.int32();
                        break;
                    }
                case 2: {
                        message.queryTable = reader.string();
                        break;
                    }
                case 3: {
                        message.queryCond = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a QueryRequestMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.QueryRequestMessage} QueryRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        QueryRequestMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a QueryRequestMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        QueryRequestMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.queryType != null && message.hasOwnProperty("queryType"))
                if (!$util.isInteger(message.queryType))
                    return "queryType: integer expected";
            if (message.queryTable != null && message.hasOwnProperty("queryTable"))
                if (!$util.isString(message.queryTable))
                    return "queryTable: string expected";
            if (message.queryCond != null && message.hasOwnProperty("queryCond"))
                if (!$util.isString(message.queryCond))
                    return "queryCond: string expected";
            return null;
        };

        /**
         * Creates a QueryRequestMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.QueryRequestMessage} QueryRequestMessage
         */
        QueryRequestMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.QueryRequestMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.QueryRequestMessage();
            if (object.queryType != null)
                message.queryType = object.queryType | 0;
            if (object.queryTable != null)
                message.queryTable = String(object.queryTable);
            if (object.queryCond != null)
                message.queryCond = String(object.queryCond);
            return message;
        };

        /**
         * Creates a plain object from a QueryRequestMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {naturalcloudsyncv2.QueryRequestMessage} message QueryRequestMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        QueryRequestMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.queryType = 0;
                object.queryTable = "";
                object.queryCond = "";
            }
            if (message.queryType != null && message.hasOwnProperty("queryType"))
                object.queryType = message.queryType;
            if (message.queryTable != null && message.hasOwnProperty("queryTable"))
                object.queryTable = message.queryTable;
            if (message.queryCond != null && message.hasOwnProperty("queryCond"))
                object.queryCond = message.queryCond;
            return object;
        };

        /**
         * Converts this QueryRequestMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        QueryRequestMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for QueryRequestMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.QueryRequestMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        QueryRequestMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.QueryRequestMessage";
        };

        return QueryRequestMessage;
    })();

    naturalcloudsyncv2.SubscribeRequestMessage = (function() {

        /**
         * Properties of a SubscribeRequestMessage.
         * @memberof naturalcloudsyncv2
         * @interface ISubscribeRequestMessage
         * @property {string|null} [subId] SubscribeRequestMessage subId
         * @property {string|null} [subStore] SubscribeRequestMessage subStore
         * @property {string|null} [subTable] SubscribeRequestMessage subTable
         * @property {string|null} [subCond] SubscribeRequestMessage subCond
         */

        /**
         * Constructs a new SubscribeRequestMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a SubscribeRequestMessage.
         * @implements ISubscribeRequestMessage
         * @constructor
         * @param {naturalcloudsyncv2.ISubscribeRequestMessage=} [properties] Properties to set
         */
        function SubscribeRequestMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * SubscribeRequestMessage subId.
         * @member {string} subId
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @instance
         */
        SubscribeRequestMessage.prototype.subId = "";

        /**
         * SubscribeRequestMessage subStore.
         * @member {string} subStore
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @instance
         */
        SubscribeRequestMessage.prototype.subStore = "";

        /**
         * SubscribeRequestMessage subTable.
         * @member {string} subTable
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @instance
         */
        SubscribeRequestMessage.prototype.subTable = "";

        /**
         * SubscribeRequestMessage subCond.
         * @member {string} subCond
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @instance
         */
        SubscribeRequestMessage.prototype.subCond = "";

        /**
         * Creates a new SubscribeRequestMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribeRequestMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.SubscribeRequestMessage} SubscribeRequestMessage instance
         */
        SubscribeRequestMessage.create = function create(properties) {
            return new SubscribeRequestMessage(properties);
        };

        /**
         * Encodes the specified SubscribeRequestMessage message. Does not implicitly {@link naturalcloudsyncv2.SubscribeRequestMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribeRequestMessage} message SubscribeRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SubscribeRequestMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.subId != null && Object.hasOwnProperty.call(message, "subId"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.subId);
            if (message.subStore != null && Object.hasOwnProperty.call(message, "subStore"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.subStore);
            if (message.subTable != null && Object.hasOwnProperty.call(message, "subTable"))
                writer.uint32(/* id 3, wireType 2 =*/26).string(message.subTable);
            if (message.subCond != null && Object.hasOwnProperty.call(message, "subCond"))
                writer.uint32(/* id 4, wireType 2 =*/34).string(message.subCond);
            return writer;
        };

        /**
         * Encodes the specified SubscribeRequestMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.SubscribeRequestMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribeRequestMessage} message SubscribeRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SubscribeRequestMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a SubscribeRequestMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.SubscribeRequestMessage} SubscribeRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SubscribeRequestMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.SubscribeRequestMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.subId = reader.string();
                        break;
                    }
                case 2: {
                        message.subStore = reader.string();
                        break;
                    }
                case 3: {
                        message.subTable = reader.string();
                        break;
                    }
                case 4: {
                        message.subCond = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a SubscribeRequestMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.SubscribeRequestMessage} SubscribeRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SubscribeRequestMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a SubscribeRequestMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        SubscribeRequestMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.subId != null && message.hasOwnProperty("subId"))
                if (!$util.isString(message.subId))
                    return "subId: string expected";
            if (message.subStore != null && message.hasOwnProperty("subStore"))
                if (!$util.isString(message.subStore))
                    return "subStore: string expected";
            if (message.subTable != null && message.hasOwnProperty("subTable"))
                if (!$util.isString(message.subTable))
                    return "subTable: string expected";
            if (message.subCond != null && message.hasOwnProperty("subCond"))
                if (!$util.isString(message.subCond))
                    return "subCond: string expected";
            return null;
        };

        /**
         * Creates a SubscribeRequestMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.SubscribeRequestMessage} SubscribeRequestMessage
         */
        SubscribeRequestMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.SubscribeRequestMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.SubscribeRequestMessage();
            if (object.subId != null)
                message.subId = String(object.subId);
            if (object.subStore != null)
                message.subStore = String(object.subStore);
            if (object.subTable != null)
                message.subTable = String(object.subTable);
            if (object.subCond != null)
                message.subCond = String(object.subCond);
            return message;
        };

        /**
         * Creates a plain object from a SubscribeRequestMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.SubscribeRequestMessage} message SubscribeRequestMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        SubscribeRequestMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.subId = "";
                object.subStore = "";
                object.subTable = "";
                object.subCond = "";
            }
            if (message.subId != null && message.hasOwnProperty("subId"))
                object.subId = message.subId;
            if (message.subStore != null && message.hasOwnProperty("subStore"))
                object.subStore = message.subStore;
            if (message.subTable != null && message.hasOwnProperty("subTable"))
                object.subTable = message.subTable;
            if (message.subCond != null && message.hasOwnProperty("subCond"))
                object.subCond = message.subCond;
            return object;
        };

        /**
         * Converts this SubscribeRequestMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        SubscribeRequestMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for SubscribeRequestMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.SubscribeRequestMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        SubscribeRequestMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.SubscribeRequestMessage";
        };

        return SubscribeRequestMessage;
    })();

    naturalcloudsyncv2.UnsubscribeRequestMessage = (function() {

        /**
         * Properties of an UnsubscribeRequestMessage.
         * @memberof naturalcloudsyncv2
         * @interface IUnsubscribeRequestMessage
         * @property {string|null} [subRecId] UnsubscribeRequestMessage subRecId
         * @property {string|null} [unSubStore] UnsubscribeRequestMessage unSubStore
         * @property {string|null} [unSubTable] UnsubscribeRequestMessage unSubTable
         * @property {number|null} [subKey] UnsubscribeRequestMessage subKey
         */

        /**
         * Constructs a new UnsubscribeRequestMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an UnsubscribeRequestMessage.
         * @implements IUnsubscribeRequestMessage
         * @constructor
         * @param {naturalcloudsyncv2.IUnsubscribeRequestMessage=} [properties] Properties to set
         */
        function UnsubscribeRequestMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * UnsubscribeRequestMessage subRecId.
         * @member {string} subRecId
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @instance
         */
        UnsubscribeRequestMessage.prototype.subRecId = "";

        /**
         * UnsubscribeRequestMessage unSubStore.
         * @member {string} unSubStore
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @instance
         */
        UnsubscribeRequestMessage.prototype.unSubStore = "";

        /**
         * UnsubscribeRequestMessage unSubTable.
         * @member {string} unSubTable
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @instance
         */
        UnsubscribeRequestMessage.prototype.unSubTable = "";

        /**
         * UnsubscribeRequestMessage subKey.
         * @member {number} subKey
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @instance
         */
        UnsubscribeRequestMessage.prototype.subKey = 0;

        /**
         * Creates a new UnsubscribeRequestMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.IUnsubscribeRequestMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.UnsubscribeRequestMessage} UnsubscribeRequestMessage instance
         */
        UnsubscribeRequestMessage.create = function create(properties) {
            return new UnsubscribeRequestMessage(properties);
        };

        /**
         * Encodes the specified UnsubscribeRequestMessage message. Does not implicitly {@link naturalcloudsyncv2.UnsubscribeRequestMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.IUnsubscribeRequestMessage} message UnsubscribeRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        UnsubscribeRequestMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.subRecId != null && Object.hasOwnProperty.call(message, "subRecId"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.subRecId);
            if (message.unSubStore != null && Object.hasOwnProperty.call(message, "unSubStore"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.unSubStore);
            if (message.unSubTable != null && Object.hasOwnProperty.call(message, "unSubTable"))
                writer.uint32(/* id 3, wireType 2 =*/26).string(message.unSubTable);
            if (message.subKey != null && Object.hasOwnProperty.call(message, "subKey"))
                writer.uint32(/* id 4, wireType 0 =*/32).int32(message.subKey);
            return writer;
        };

        /**
         * Encodes the specified UnsubscribeRequestMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.UnsubscribeRequestMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.IUnsubscribeRequestMessage} message UnsubscribeRequestMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        UnsubscribeRequestMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an UnsubscribeRequestMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.UnsubscribeRequestMessage} UnsubscribeRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        UnsubscribeRequestMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.UnsubscribeRequestMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.subRecId = reader.string();
                        break;
                    }
                case 2: {
                        message.unSubStore = reader.string();
                        break;
                    }
                case 3: {
                        message.unSubTable = reader.string();
                        break;
                    }
                case 4: {
                        message.subKey = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an UnsubscribeRequestMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.UnsubscribeRequestMessage} UnsubscribeRequestMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        UnsubscribeRequestMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an UnsubscribeRequestMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        UnsubscribeRequestMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.subRecId != null && message.hasOwnProperty("subRecId"))
                if (!$util.isString(message.subRecId))
                    return "subRecId: string expected";
            if (message.unSubStore != null && message.hasOwnProperty("unSubStore"))
                if (!$util.isString(message.unSubStore))
                    return "unSubStore: string expected";
            if (message.unSubTable != null && message.hasOwnProperty("unSubTable"))
                if (!$util.isString(message.unSubTable))
                    return "unSubTable: string expected";
            if (message.subKey != null && message.hasOwnProperty("subKey"))
                if (!$util.isInteger(message.subKey))
                    return "subKey: integer expected";
            return null;
        };

        /**
         * Creates an UnsubscribeRequestMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.UnsubscribeRequestMessage} UnsubscribeRequestMessage
         */
        UnsubscribeRequestMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.UnsubscribeRequestMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.UnsubscribeRequestMessage();
            if (object.subRecId != null)
                message.subRecId = String(object.subRecId);
            if (object.unSubStore != null)
                message.unSubStore = String(object.unSubStore);
            if (object.unSubTable != null)
                message.unSubTable = String(object.unSubTable);
            if (object.subKey != null)
                message.subKey = object.subKey | 0;
            return message;
        };

        /**
         * Creates a plain object from an UnsubscribeRequestMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {naturalcloudsyncv2.UnsubscribeRequestMessage} message UnsubscribeRequestMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        UnsubscribeRequestMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.subRecId = "";
                object.unSubStore = "";
                object.unSubTable = "";
                object.subKey = 0;
            }
            if (message.subRecId != null && message.hasOwnProperty("subRecId"))
                object.subRecId = message.subRecId;
            if (message.unSubStore != null && message.hasOwnProperty("unSubStore"))
                object.unSubStore = message.unSubStore;
            if (message.unSubTable != null && message.hasOwnProperty("unSubTable"))
                object.unSubTable = message.unSubTable;
            if (message.subKey != null && message.hasOwnProperty("subKey"))
                object.subKey = message.subKey;
            return object;
        };

        /**
         * Converts this UnsubscribeRequestMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        UnsubscribeRequestMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for UnsubscribeRequestMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.UnsubscribeRequestMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        UnsubscribeRequestMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.UnsubscribeRequestMessage";
        };

        return UnsubscribeRequestMessage;
    })();

    naturalcloudsyncv2.ServerStatus = (function() {

        /**
         * Properties of a ServerStatus.
         * @memberof naturalcloudsyncv2
         * @interface IServerStatus
         * @property {Long|null} [timestamp] ServerStatus timestamp
         */

        /**
         * Constructs a new ServerStatus.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a ServerStatus.
         * @implements IServerStatus
         * @constructor
         * @param {naturalcloudsyncv2.IServerStatus=} [properties] Properties to set
         */
        function ServerStatus(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * ServerStatus timestamp.
         * @member {Long} timestamp
         * @memberof naturalcloudsyncv2.ServerStatus
         * @instance
         */
        ServerStatus.prototype.timestamp = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * Creates a new ServerStatus instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {naturalcloudsyncv2.IServerStatus=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.ServerStatus} ServerStatus instance
         */
        ServerStatus.create = function create(properties) {
            return new ServerStatus(properties);
        };

        /**
         * Encodes the specified ServerStatus message. Does not implicitly {@link naturalcloudsyncv2.ServerStatus.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {naturalcloudsyncv2.IServerStatus} message ServerStatus message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ServerStatus.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.timestamp != null && Object.hasOwnProperty.call(message, "timestamp"))
                writer.uint32(/* id 1, wireType 0 =*/8).int64(message.timestamp);
            return writer;
        };

        /**
         * Encodes the specified ServerStatus message, length delimited. Does not implicitly {@link naturalcloudsyncv2.ServerStatus.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {naturalcloudsyncv2.IServerStatus} message ServerStatus message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ServerStatus.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a ServerStatus message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.ServerStatus} ServerStatus
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ServerStatus.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.ServerStatus();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.timestamp = reader.int64();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a ServerStatus message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.ServerStatus} ServerStatus
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ServerStatus.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a ServerStatus message.
         * @function verify
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        ServerStatus.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.timestamp != null && message.hasOwnProperty("timestamp"))
                if (!$util.isInteger(message.timestamp) && !(message.timestamp && $util.isInteger(message.timestamp.low) && $util.isInteger(message.timestamp.high)))
                    return "timestamp: integer|Long expected";
            return null;
        };

        /**
         * Creates a ServerStatus message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.ServerStatus} ServerStatus
         */
        ServerStatus.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.ServerStatus)
                return object;
            let message = new $root.naturalcloudsyncv2.ServerStatus();
            if (object.timestamp != null)
                if ($util.Long)
                    (message.timestamp = $util.Long.fromValue(object.timestamp)).unsigned = false;
                else if (typeof object.timestamp === "string")
                    message.timestamp = parseInt(object.timestamp, 10);
                else if (typeof object.timestamp === "number")
                    message.timestamp = object.timestamp;
                else if (typeof object.timestamp === "object")
                    message.timestamp = new $util.LongBits(object.timestamp.low >>> 0, object.timestamp.high >>> 0).toNumber();
            return message;
        };

        /**
         * Creates a plain object from a ServerStatus message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {naturalcloudsyncv2.ServerStatus} message ServerStatus
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        ServerStatus.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults)
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.timestamp = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.timestamp = options.longs === String ? "0" : 0;
            if (message.timestamp != null && message.hasOwnProperty("timestamp"))
                if (typeof message.timestamp === "number")
                    object.timestamp = options.longs === String ? String(message.timestamp) : message.timestamp;
                else
                    object.timestamp = options.longs === String ? $util.Long.prototype.toString.call(message.timestamp) : options.longs === Number ? new $util.LongBits(message.timestamp.low >>> 0, message.timestamp.high >>> 0).toNumber() : message.timestamp;
            return object;
        };

        /**
         * Converts this ServerStatus to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.ServerStatus
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        ServerStatus.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for ServerStatus
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.ServerStatus
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        ServerStatus.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.ServerStatus";
        };

        return ServerStatus;
    })();

    naturalcloudsyncv2.SyncResponseMessage = (function() {

        /**
         * Properties of a SyncResponseMessage.
         * @memberof naturalcloudsyncv2
         * @interface ISyncResponseMessage
         * @property {naturalcloudsyncv2.IMessageInfo|null} [msgInfo] SyncResponseMessage msgInfo
         * @property {naturalcloudsyncv2.IResponseInfo|null} [resInfo] SyncResponseMessage resInfo
         * @property {Array.<naturalcloudsyncv2.ISchema>|null} [schemas] SyncResponseMessage schemas
         * @property {Array.<naturalcloudsyncv2.IOperationData>|null} [opData] SyncResponseMessage opData
         * @property {Array.<naturalcloudsyncv2.IPermissionRecord>|null} [permRecs] SyncResponseMessage permRecs
         * @property {naturalcloudsyncv2.IUpdateResponseMessage|null} [updateResMsg] SyncResponseMessage updateResMsg
         * @property {naturalcloudsyncv2.IQueryResponseMessage|null} [queryResMsg] SyncResponseMessage queryResMsg
         * @property {Array.<naturalcloudsyncv2.ISubscribeResponseMessage>|null} [subResMsg] SyncResponseMessage subResMsg
         * @property {Array.<naturalcloudsyncv2.IUnsubscribeResponseMessage>|null} [unSubResMsg] SyncResponseMessage unSubResMsg
         * @property {naturalcloudsyncv2.ISubscribePushMessage|null} [subPushMsg] SyncResponseMessage subPushMsg
         * @property {Array.<naturalcloudsyncv2.IEncryptionInfo>|null} [enResInfo] SyncResponseMessage enResInfo
         * @property {naturalcloudsyncv2.IServerStatus|null} [serverStatus] SyncResponseMessage serverStatus
         */

        /**
         * Constructs a new SyncResponseMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a SyncResponseMessage.
         * @implements ISyncResponseMessage
         * @constructor
         * @param {naturalcloudsyncv2.ISyncResponseMessage=} [properties] Properties to set
         */
        function SyncResponseMessage(properties) {
            this.schemas = [];
            this.opData = [];
            this.permRecs = [];
            this.subResMsg = [];
            this.unSubResMsg = [];
            this.enResInfo = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * SyncResponseMessage msgInfo.
         * @member {naturalcloudsyncv2.IMessageInfo|null|undefined} msgInfo
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.msgInfo = null;

        /**
         * SyncResponseMessage resInfo.
         * @member {naturalcloudsyncv2.IResponseInfo|null|undefined} resInfo
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.resInfo = null;

        /**
         * SyncResponseMessage schemas.
         * @member {Array.<naturalcloudsyncv2.ISchema>} schemas
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.schemas = $util.emptyArray;

        /**
         * SyncResponseMessage opData.
         * @member {Array.<naturalcloudsyncv2.IOperationData>} opData
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.opData = $util.emptyArray;

        /**
         * SyncResponseMessage permRecs.
         * @member {Array.<naturalcloudsyncv2.IPermissionRecord>} permRecs
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.permRecs = $util.emptyArray;

        /**
         * SyncResponseMessage updateResMsg.
         * @member {naturalcloudsyncv2.IUpdateResponseMessage|null|undefined} updateResMsg
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.updateResMsg = null;

        /**
         * SyncResponseMessage queryResMsg.
         * @member {naturalcloudsyncv2.IQueryResponseMessage|null|undefined} queryResMsg
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.queryResMsg = null;

        /**
         * SyncResponseMessage subResMsg.
         * @member {Array.<naturalcloudsyncv2.ISubscribeResponseMessage>} subResMsg
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.subResMsg = $util.emptyArray;

        /**
         * SyncResponseMessage unSubResMsg.
         * @member {Array.<naturalcloudsyncv2.IUnsubscribeResponseMessage>} unSubResMsg
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.unSubResMsg = $util.emptyArray;

        /**
         * SyncResponseMessage subPushMsg.
         * @member {naturalcloudsyncv2.ISubscribePushMessage|null|undefined} subPushMsg
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.subPushMsg = null;

        /**
         * SyncResponseMessage enResInfo.
         * @member {Array.<naturalcloudsyncv2.IEncryptionInfo>} enResInfo
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.enResInfo = $util.emptyArray;

        /**
         * SyncResponseMessage serverStatus.
         * @member {naturalcloudsyncv2.IServerStatus|null|undefined} serverStatus
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         */
        SyncResponseMessage.prototype.serverStatus = null;

        /**
         * Creates a new SyncResponseMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {naturalcloudsyncv2.ISyncResponseMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.SyncResponseMessage} SyncResponseMessage instance
         */
        SyncResponseMessage.create = function create(properties) {
            return new SyncResponseMessage(properties);
        };

        /**
         * Encodes the specified SyncResponseMessage message. Does not implicitly {@link naturalcloudsyncv2.SyncResponseMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {naturalcloudsyncv2.ISyncResponseMessage} message SyncResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SyncResponseMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.msgInfo != null && Object.hasOwnProperty.call(message, "msgInfo"))
                $root.naturalcloudsyncv2.MessageInfo.encode(message.msgInfo, writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
            if (message.resInfo != null && Object.hasOwnProperty.call(message, "resInfo"))
                $root.naturalcloudsyncv2.ResponseInfo.encode(message.resInfo, writer.uint32(/* id 2, wireType 2 =*/18).fork()).ldelim();
            if (message.schemas != null && message.schemas.length)
                for (let i = 0; i < message.schemas.length; ++i)
                    $root.naturalcloudsyncv2.Schema.encode(message.schemas[i], writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
            if (message.opData != null && message.opData.length)
                for (let i = 0; i < message.opData.length; ++i)
                    $root.naturalcloudsyncv2.OperationData.encode(message.opData[i], writer.uint32(/* id 4, wireType 2 =*/34).fork()).ldelim();
            if (message.permRecs != null && message.permRecs.length)
                for (let i = 0; i < message.permRecs.length; ++i)
                    $root.naturalcloudsyncv2.PermissionRecord.encode(message.permRecs[i], writer.uint32(/* id 5, wireType 2 =*/42).fork()).ldelim();
            if (message.updateResMsg != null && Object.hasOwnProperty.call(message, "updateResMsg"))
                $root.naturalcloudsyncv2.UpdateResponseMessage.encode(message.updateResMsg, writer.uint32(/* id 6, wireType 2 =*/50).fork()).ldelim();
            if (message.queryResMsg != null && Object.hasOwnProperty.call(message, "queryResMsg"))
                $root.naturalcloudsyncv2.QueryResponseMessage.encode(message.queryResMsg, writer.uint32(/* id 7, wireType 2 =*/58).fork()).ldelim();
            if (message.subResMsg != null && message.subResMsg.length)
                for (let i = 0; i < message.subResMsg.length; ++i)
                    $root.naturalcloudsyncv2.SubscribeResponseMessage.encode(message.subResMsg[i], writer.uint32(/* id 8, wireType 2 =*/66).fork()).ldelim();
            if (message.unSubResMsg != null && message.unSubResMsg.length)
                for (let i = 0; i < message.unSubResMsg.length; ++i)
                    $root.naturalcloudsyncv2.UnsubscribeResponseMessage.encode(message.unSubResMsg[i], writer.uint32(/* id 9, wireType 2 =*/74).fork()).ldelim();
            if (message.subPushMsg != null && Object.hasOwnProperty.call(message, "subPushMsg"))
                $root.naturalcloudsyncv2.SubscribePushMessage.encode(message.subPushMsg, writer.uint32(/* id 10, wireType 2 =*/82).fork()).ldelim();
            if (message.enResInfo != null && message.enResInfo.length)
                for (let i = 0; i < message.enResInfo.length; ++i)
                    $root.naturalcloudsyncv2.EncryptionInfo.encode(message.enResInfo[i], writer.uint32(/* id 11, wireType 2 =*/90).fork()).ldelim();
            if (message.serverStatus != null && Object.hasOwnProperty.call(message, "serverStatus"))
                $root.naturalcloudsyncv2.ServerStatus.encode(message.serverStatus, writer.uint32(/* id 12, wireType 2 =*/98).fork()).ldelim();
            return writer;
        };

        /**
         * Encodes the specified SyncResponseMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.SyncResponseMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {naturalcloudsyncv2.ISyncResponseMessage} message SyncResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SyncResponseMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a SyncResponseMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.SyncResponseMessage} SyncResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SyncResponseMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.SyncResponseMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.msgInfo = $root.naturalcloudsyncv2.MessageInfo.decode(reader, reader.uint32());
                        break;
                    }
                case 2: {
                        message.resInfo = $root.naturalcloudsyncv2.ResponseInfo.decode(reader, reader.uint32());
                        break;
                    }
                case 3: {
                        if (!(message.schemas && message.schemas.length))
                            message.schemas = [];
                        message.schemas.push($root.naturalcloudsyncv2.Schema.decode(reader, reader.uint32()));
                        break;
                    }
                case 4: {
                        if (!(message.opData && message.opData.length))
                            message.opData = [];
                        message.opData.push($root.naturalcloudsyncv2.OperationData.decode(reader, reader.uint32()));
                        break;
                    }
                case 5: {
                        if (!(message.permRecs && message.permRecs.length))
                            message.permRecs = [];
                        message.permRecs.push($root.naturalcloudsyncv2.PermissionRecord.decode(reader, reader.uint32()));
                        break;
                    }
                case 6: {
                        message.updateResMsg = $root.naturalcloudsyncv2.UpdateResponseMessage.decode(reader, reader.uint32());
                        break;
                    }
                case 7: {
                        message.queryResMsg = $root.naturalcloudsyncv2.QueryResponseMessage.decode(reader, reader.uint32());
                        break;
                    }
                case 8: {
                        if (!(message.subResMsg && message.subResMsg.length))
                            message.subResMsg = [];
                        message.subResMsg.push($root.naturalcloudsyncv2.SubscribeResponseMessage.decode(reader, reader.uint32()));
                        break;
                    }
                case 9: {
                        if (!(message.unSubResMsg && message.unSubResMsg.length))
                            message.unSubResMsg = [];
                        message.unSubResMsg.push($root.naturalcloudsyncv2.UnsubscribeResponseMessage.decode(reader, reader.uint32()));
                        break;
                    }
                case 10: {
                        message.subPushMsg = $root.naturalcloudsyncv2.SubscribePushMessage.decode(reader, reader.uint32());
                        break;
                    }
                case 11: {
                        if (!(message.enResInfo && message.enResInfo.length))
                            message.enResInfo = [];
                        message.enResInfo.push($root.naturalcloudsyncv2.EncryptionInfo.decode(reader, reader.uint32()));
                        break;
                    }
                case 12: {
                        message.serverStatus = $root.naturalcloudsyncv2.ServerStatus.decode(reader, reader.uint32());
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a SyncResponseMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.SyncResponseMessage} SyncResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SyncResponseMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a SyncResponseMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        SyncResponseMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.msgInfo != null && message.hasOwnProperty("msgInfo")) {
                let error = $root.naturalcloudsyncv2.MessageInfo.verify(message.msgInfo);
                if (error)
                    return "msgInfo." + error;
            }
            if (message.resInfo != null && message.hasOwnProperty("resInfo")) {
                let error = $root.naturalcloudsyncv2.ResponseInfo.verify(message.resInfo);
                if (error)
                    return "resInfo." + error;
            }
            if (message.schemas != null && message.hasOwnProperty("schemas")) {
                if (!Array.isArray(message.schemas))
                    return "schemas: array expected";
                for (let i = 0; i < message.schemas.length; ++i) {
                    let error = $root.naturalcloudsyncv2.Schema.verify(message.schemas[i]);
                    if (error)
                        return "schemas." + error;
                }
            }
            if (message.opData != null && message.hasOwnProperty("opData")) {
                if (!Array.isArray(message.opData))
                    return "opData: array expected";
                for (let i = 0; i < message.opData.length; ++i) {
                    let error = $root.naturalcloudsyncv2.OperationData.verify(message.opData[i]);
                    if (error)
                        return "opData." + error;
                }
            }
            if (message.permRecs != null && message.hasOwnProperty("permRecs")) {
                if (!Array.isArray(message.permRecs))
                    return "permRecs: array expected";
                for (let i = 0; i < message.permRecs.length; ++i) {
                    let error = $root.naturalcloudsyncv2.PermissionRecord.verify(message.permRecs[i]);
                    if (error)
                        return "permRecs." + error;
                }
            }
            if (message.updateResMsg != null && message.hasOwnProperty("updateResMsg")) {
                let error = $root.naturalcloudsyncv2.UpdateResponseMessage.verify(message.updateResMsg);
                if (error)
                    return "updateResMsg." + error;
            }
            if (message.queryResMsg != null && message.hasOwnProperty("queryResMsg")) {
                let error = $root.naturalcloudsyncv2.QueryResponseMessage.verify(message.queryResMsg);
                if (error)
                    return "queryResMsg." + error;
            }
            if (message.subResMsg != null && message.hasOwnProperty("subResMsg")) {
                if (!Array.isArray(message.subResMsg))
                    return "subResMsg: array expected";
                for (let i = 0; i < message.subResMsg.length; ++i) {
                    let error = $root.naturalcloudsyncv2.SubscribeResponseMessage.verify(message.subResMsg[i]);
                    if (error)
                        return "subResMsg." + error;
                }
            }
            if (message.unSubResMsg != null && message.hasOwnProperty("unSubResMsg")) {
                if (!Array.isArray(message.unSubResMsg))
                    return "unSubResMsg: array expected";
                for (let i = 0; i < message.unSubResMsg.length; ++i) {
                    let error = $root.naturalcloudsyncv2.UnsubscribeResponseMessage.verify(message.unSubResMsg[i]);
                    if (error)
                        return "unSubResMsg." + error;
                }
            }
            if (message.subPushMsg != null && message.hasOwnProperty("subPushMsg")) {
                let error = $root.naturalcloudsyncv2.SubscribePushMessage.verify(message.subPushMsg);
                if (error)
                    return "subPushMsg." + error;
            }
            if (message.enResInfo != null && message.hasOwnProperty("enResInfo")) {
                if (!Array.isArray(message.enResInfo))
                    return "enResInfo: array expected";
                for (let i = 0; i < message.enResInfo.length; ++i) {
                    let error = $root.naturalcloudsyncv2.EncryptionInfo.verify(message.enResInfo[i]);
                    if (error)
                        return "enResInfo." + error;
                }
            }
            if (message.serverStatus != null && message.hasOwnProperty("serverStatus")) {
                let error = $root.naturalcloudsyncv2.ServerStatus.verify(message.serverStatus);
                if (error)
                    return "serverStatus." + error;
            }
            return null;
        };

        /**
         * Creates a SyncResponseMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.SyncResponseMessage} SyncResponseMessage
         */
        SyncResponseMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.SyncResponseMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.SyncResponseMessage();
            if (object.msgInfo != null) {
                if (typeof object.msgInfo !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.msgInfo: object expected");
                message.msgInfo = $root.naturalcloudsyncv2.MessageInfo.fromObject(object.msgInfo);
            }
            if (object.resInfo != null) {
                if (typeof object.resInfo !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.resInfo: object expected");
                message.resInfo = $root.naturalcloudsyncv2.ResponseInfo.fromObject(object.resInfo);
            }
            if (object.schemas) {
                if (!Array.isArray(object.schemas))
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.schemas: array expected");
                message.schemas = [];
                for (let i = 0; i < object.schemas.length; ++i) {
                    if (typeof object.schemas[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.schemas: object expected");
                    message.schemas[i] = $root.naturalcloudsyncv2.Schema.fromObject(object.schemas[i]);
                }
            }
            if (object.opData) {
                if (!Array.isArray(object.opData))
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.opData: array expected");
                message.opData = [];
                for (let i = 0; i < object.opData.length; ++i) {
                    if (typeof object.opData[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.opData: object expected");
                    message.opData[i] = $root.naturalcloudsyncv2.OperationData.fromObject(object.opData[i]);
                }
            }
            if (object.permRecs) {
                if (!Array.isArray(object.permRecs))
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.permRecs: array expected");
                message.permRecs = [];
                for (let i = 0; i < object.permRecs.length; ++i) {
                    if (typeof object.permRecs[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.permRecs: object expected");
                    message.permRecs[i] = $root.naturalcloudsyncv2.PermissionRecord.fromObject(object.permRecs[i]);
                }
            }
            if (object.updateResMsg != null) {
                if (typeof object.updateResMsg !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.updateResMsg: object expected");
                message.updateResMsg = $root.naturalcloudsyncv2.UpdateResponseMessage.fromObject(object.updateResMsg);
            }
            if (object.queryResMsg != null) {
                if (typeof object.queryResMsg !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.queryResMsg: object expected");
                message.queryResMsg = $root.naturalcloudsyncv2.QueryResponseMessage.fromObject(object.queryResMsg);
            }
            if (object.subResMsg) {
                if (!Array.isArray(object.subResMsg))
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.subResMsg: array expected");
                message.subResMsg = [];
                for (let i = 0; i < object.subResMsg.length; ++i) {
                    if (typeof object.subResMsg[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.subResMsg: object expected");
                    message.subResMsg[i] = $root.naturalcloudsyncv2.SubscribeResponseMessage.fromObject(object.subResMsg[i]);
                }
            }
            if (object.unSubResMsg) {
                if (!Array.isArray(object.unSubResMsg))
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.unSubResMsg: array expected");
                message.unSubResMsg = [];
                for (let i = 0; i < object.unSubResMsg.length; ++i) {
                    if (typeof object.unSubResMsg[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.unSubResMsg: object expected");
                    message.unSubResMsg[i] = $root.naturalcloudsyncv2.UnsubscribeResponseMessage.fromObject(object.unSubResMsg[i]);
                }
            }
            if (object.subPushMsg != null) {
                if (typeof object.subPushMsg !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.subPushMsg: object expected");
                message.subPushMsg = $root.naturalcloudsyncv2.SubscribePushMessage.fromObject(object.subPushMsg);
            }
            if (object.enResInfo) {
                if (!Array.isArray(object.enResInfo))
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.enResInfo: array expected");
                message.enResInfo = [];
                for (let i = 0; i < object.enResInfo.length; ++i) {
                    if (typeof object.enResInfo[i] !== "object")
                        throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.enResInfo: object expected");
                    message.enResInfo[i] = $root.naturalcloudsyncv2.EncryptionInfo.fromObject(object.enResInfo[i]);
                }
            }
            if (object.serverStatus != null) {
                if (typeof object.serverStatus !== "object")
                    throw TypeError(".naturalcloudsyncv2.SyncResponseMessage.serverStatus: object expected");
                message.serverStatus = $root.naturalcloudsyncv2.ServerStatus.fromObject(object.serverStatus);
            }
            return message;
        };

        /**
         * Creates a plain object from a SyncResponseMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {naturalcloudsyncv2.SyncResponseMessage} message SyncResponseMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        SyncResponseMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.arrays || options.defaults) {
                object.schemas = [];
                object.opData = [];
                object.permRecs = [];
                object.subResMsg = [];
                object.unSubResMsg = [];
                object.enResInfo = [];
            }
            if (options.defaults) {
                object.msgInfo = null;
                object.resInfo = null;
                object.updateResMsg = null;
                object.queryResMsg = null;
                object.subPushMsg = null;
                object.serverStatus = null;
            }
            if (message.msgInfo != null && message.hasOwnProperty("msgInfo"))
                object.msgInfo = $root.naturalcloudsyncv2.MessageInfo.toObject(message.msgInfo, options);
            if (message.resInfo != null && message.hasOwnProperty("resInfo"))
                object.resInfo = $root.naturalcloudsyncv2.ResponseInfo.toObject(message.resInfo, options);
            if (message.schemas && message.schemas.length) {
                object.schemas = [];
                for (let j = 0; j < message.schemas.length; ++j)
                    object.schemas[j] = $root.naturalcloudsyncv2.Schema.toObject(message.schemas[j], options);
            }
            if (message.opData && message.opData.length) {
                object.opData = [];
                for (let j = 0; j < message.opData.length; ++j)
                    object.opData[j] = $root.naturalcloudsyncv2.OperationData.toObject(message.opData[j], options);
            }
            if (message.permRecs && message.permRecs.length) {
                object.permRecs = [];
                for (let j = 0; j < message.permRecs.length; ++j)
                    object.permRecs[j] = $root.naturalcloudsyncv2.PermissionRecord.toObject(message.permRecs[j], options);
            }
            if (message.updateResMsg != null && message.hasOwnProperty("updateResMsg"))
                object.updateResMsg = $root.naturalcloudsyncv2.UpdateResponseMessage.toObject(message.updateResMsg, options);
            if (message.queryResMsg != null && message.hasOwnProperty("queryResMsg"))
                object.queryResMsg = $root.naturalcloudsyncv2.QueryResponseMessage.toObject(message.queryResMsg, options);
            if (message.subResMsg && message.subResMsg.length) {
                object.subResMsg = [];
                for (let j = 0; j < message.subResMsg.length; ++j)
                    object.subResMsg[j] = $root.naturalcloudsyncv2.SubscribeResponseMessage.toObject(message.subResMsg[j], options);
            }
            if (message.unSubResMsg && message.unSubResMsg.length) {
                object.unSubResMsg = [];
                for (let j = 0; j < message.unSubResMsg.length; ++j)
                    object.unSubResMsg[j] = $root.naturalcloudsyncv2.UnsubscribeResponseMessage.toObject(message.unSubResMsg[j], options);
            }
            if (message.subPushMsg != null && message.hasOwnProperty("subPushMsg"))
                object.subPushMsg = $root.naturalcloudsyncv2.SubscribePushMessage.toObject(message.subPushMsg, options);
            if (message.enResInfo && message.enResInfo.length) {
                object.enResInfo = [];
                for (let j = 0; j < message.enResInfo.length; ++j)
                    object.enResInfo[j] = $root.naturalcloudsyncv2.EncryptionInfo.toObject(message.enResInfo[j], options);
            }
            if (message.serverStatus != null && message.hasOwnProperty("serverStatus"))
                object.serverStatus = $root.naturalcloudsyncv2.ServerStatus.toObject(message.serverStatus, options);
            return object;
        };

        /**
         * Converts this SyncResponseMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        SyncResponseMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for SyncResponseMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.SyncResponseMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        SyncResponseMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.SyncResponseMessage";
        };

        return SyncResponseMessage;
    })();

    naturalcloudsyncv2.ResponseInfo = (function() {

        /**
         * Properties of a ResponseInfo.
         * @memberof naturalcloudsyncv2
         * @interface IResponseInfo
         * @property {number|null} [resCode] ResponseInfo resCode
         * @property {string|null} [resInfo] ResponseInfo resInfo
         */

        /**
         * Constructs a new ResponseInfo.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a ResponseInfo.
         * @implements IResponseInfo
         * @constructor
         * @param {naturalcloudsyncv2.IResponseInfo=} [properties] Properties to set
         */
        function ResponseInfo(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * ResponseInfo resCode.
         * @member {number} resCode
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @instance
         */
        ResponseInfo.prototype.resCode = 0;

        /**
         * ResponseInfo resInfo.
         * @member {string} resInfo
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @instance
         */
        ResponseInfo.prototype.resInfo = "";

        /**
         * Creates a new ResponseInfo instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {naturalcloudsyncv2.IResponseInfo=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.ResponseInfo} ResponseInfo instance
         */
        ResponseInfo.create = function create(properties) {
            return new ResponseInfo(properties);
        };

        /**
         * Encodes the specified ResponseInfo message. Does not implicitly {@link naturalcloudsyncv2.ResponseInfo.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {naturalcloudsyncv2.IResponseInfo} message ResponseInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ResponseInfo.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.resCode != null && Object.hasOwnProperty.call(message, "resCode"))
                writer.uint32(/* id 1, wireType 0 =*/8).int32(message.resCode);
            if (message.resInfo != null && Object.hasOwnProperty.call(message, "resInfo"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.resInfo);
            return writer;
        };

        /**
         * Encodes the specified ResponseInfo message, length delimited. Does not implicitly {@link naturalcloudsyncv2.ResponseInfo.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {naturalcloudsyncv2.IResponseInfo} message ResponseInfo message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ResponseInfo.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a ResponseInfo message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.ResponseInfo} ResponseInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ResponseInfo.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.ResponseInfo();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.resCode = reader.int32();
                        break;
                    }
                case 2: {
                        message.resInfo = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a ResponseInfo message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.ResponseInfo} ResponseInfo
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ResponseInfo.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a ResponseInfo message.
         * @function verify
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        ResponseInfo.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.resCode != null && message.hasOwnProperty("resCode"))
                if (!$util.isInteger(message.resCode))
                    return "resCode: integer expected";
            if (message.resInfo != null && message.hasOwnProperty("resInfo"))
                if (!$util.isString(message.resInfo))
                    return "resInfo: string expected";
            return null;
        };

        /**
         * Creates a ResponseInfo message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.ResponseInfo} ResponseInfo
         */
        ResponseInfo.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.ResponseInfo)
                return object;
            let message = new $root.naturalcloudsyncv2.ResponseInfo();
            if (object.resCode != null)
                message.resCode = object.resCode | 0;
            if (object.resInfo != null)
                message.resInfo = String(object.resInfo);
            return message;
        };

        /**
         * Creates a plain object from a ResponseInfo message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {naturalcloudsyncv2.ResponseInfo} message ResponseInfo
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        ResponseInfo.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.resCode = 0;
                object.resInfo = "";
            }
            if (message.resCode != null && message.hasOwnProperty("resCode"))
                object.resCode = message.resCode;
            if (message.resInfo != null && message.hasOwnProperty("resInfo"))
                object.resInfo = message.resInfo;
            return object;
        };

        /**
         * Converts this ResponseInfo to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        ResponseInfo.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for ResponseInfo
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.ResponseInfo
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        ResponseInfo.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.ResponseInfo";
        };

        return ResponseInfo;
    })();

    naturalcloudsyncv2.PermissionRecord = (function() {

        /**
         * Properties of a PermissionRecord.
         * @memberof naturalcloudsyncv2
         * @interface IPermissionRecord
         * @property {string|null} [tableName] PermissionRecord tableName
         * @property {string|null} [roleType] PermissionRecord roleType
         * @property {boolean|null} [readPerm] PermissionRecord readPerm
         * @property {boolean|null} [upsertPerm] PermissionRecord upsertPerm
         * @property {boolean|null} [deletePerm] PermissionRecord deletePerm
         */

        /**
         * Constructs a new PermissionRecord.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a PermissionRecord.
         * @implements IPermissionRecord
         * @constructor
         * @param {naturalcloudsyncv2.IPermissionRecord=} [properties] Properties to set
         */
        function PermissionRecord(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * PermissionRecord tableName.
         * @member {string} tableName
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @instance
         */
        PermissionRecord.prototype.tableName = "";

        /**
         * PermissionRecord roleType.
         * @member {string} roleType
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @instance
         */
        PermissionRecord.prototype.roleType = "";

        /**
         * PermissionRecord readPerm.
         * @member {boolean} readPerm
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @instance
         */
        PermissionRecord.prototype.readPerm = false;

        /**
         * PermissionRecord upsertPerm.
         * @member {boolean} upsertPerm
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @instance
         */
        PermissionRecord.prototype.upsertPerm = false;

        /**
         * PermissionRecord deletePerm.
         * @member {boolean} deletePerm
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @instance
         */
        PermissionRecord.prototype.deletePerm = false;

        /**
         * Creates a new PermissionRecord instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {naturalcloudsyncv2.IPermissionRecord=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.PermissionRecord} PermissionRecord instance
         */
        PermissionRecord.create = function create(properties) {
            return new PermissionRecord(properties);
        };

        /**
         * Encodes the specified PermissionRecord message. Does not implicitly {@link naturalcloudsyncv2.PermissionRecord.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {naturalcloudsyncv2.IPermissionRecord} message PermissionRecord message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        PermissionRecord.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.tableName != null && Object.hasOwnProperty.call(message, "tableName"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.tableName);
            if (message.roleType != null && Object.hasOwnProperty.call(message, "roleType"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.roleType);
            if (message.readPerm != null && Object.hasOwnProperty.call(message, "readPerm"))
                writer.uint32(/* id 3, wireType 0 =*/24).bool(message.readPerm);
            if (message.upsertPerm != null && Object.hasOwnProperty.call(message, "upsertPerm"))
                writer.uint32(/* id 4, wireType 0 =*/32).bool(message.upsertPerm);
            if (message.deletePerm != null && Object.hasOwnProperty.call(message, "deletePerm"))
                writer.uint32(/* id 5, wireType 0 =*/40).bool(message.deletePerm);
            return writer;
        };

        /**
         * Encodes the specified PermissionRecord message, length delimited. Does not implicitly {@link naturalcloudsyncv2.PermissionRecord.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {naturalcloudsyncv2.IPermissionRecord} message PermissionRecord message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        PermissionRecord.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a PermissionRecord message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.PermissionRecord} PermissionRecord
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        PermissionRecord.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.PermissionRecord();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.tableName = reader.string();
                        break;
                    }
                case 2: {
                        message.roleType = reader.string();
                        break;
                    }
                case 3: {
                        message.readPerm = reader.bool();
                        break;
                    }
                case 4: {
                        message.upsertPerm = reader.bool();
                        break;
                    }
                case 5: {
                        message.deletePerm = reader.bool();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a PermissionRecord message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.PermissionRecord} PermissionRecord
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        PermissionRecord.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a PermissionRecord message.
         * @function verify
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        PermissionRecord.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.tableName != null && message.hasOwnProperty("tableName"))
                if (!$util.isString(message.tableName))
                    return "tableName: string expected";
            if (message.roleType != null && message.hasOwnProperty("roleType"))
                if (!$util.isString(message.roleType))
                    return "roleType: string expected";
            if (message.readPerm != null && message.hasOwnProperty("readPerm"))
                if (typeof message.readPerm !== "boolean")
                    return "readPerm: boolean expected";
            if (message.upsertPerm != null && message.hasOwnProperty("upsertPerm"))
                if (typeof message.upsertPerm !== "boolean")
                    return "upsertPerm: boolean expected";
            if (message.deletePerm != null && message.hasOwnProperty("deletePerm"))
                if (typeof message.deletePerm !== "boolean")
                    return "deletePerm: boolean expected";
            return null;
        };

        /**
         * Creates a PermissionRecord message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.PermissionRecord} PermissionRecord
         */
        PermissionRecord.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.PermissionRecord)
                return object;
            let message = new $root.naturalcloudsyncv2.PermissionRecord();
            if (object.tableName != null)
                message.tableName = String(object.tableName);
            if (object.roleType != null)
                message.roleType = String(object.roleType);
            if (object.readPerm != null)
                message.readPerm = Boolean(object.readPerm);
            if (object.upsertPerm != null)
                message.upsertPerm = Boolean(object.upsertPerm);
            if (object.deletePerm != null)
                message.deletePerm = Boolean(object.deletePerm);
            return message;
        };

        /**
         * Creates a plain object from a PermissionRecord message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {naturalcloudsyncv2.PermissionRecord} message PermissionRecord
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        PermissionRecord.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.tableName = "";
                object.roleType = "";
                object.readPerm = false;
                object.upsertPerm = false;
                object.deletePerm = false;
            }
            if (message.tableName != null && message.hasOwnProperty("tableName"))
                object.tableName = message.tableName;
            if (message.roleType != null && message.hasOwnProperty("roleType"))
                object.roleType = message.roleType;
            if (message.readPerm != null && message.hasOwnProperty("readPerm"))
                object.readPerm = message.readPerm;
            if (message.upsertPerm != null && message.hasOwnProperty("upsertPerm"))
                object.upsertPerm = message.upsertPerm;
            if (message.deletePerm != null && message.hasOwnProperty("deletePerm"))
                object.deletePerm = message.deletePerm;
            return object;
        };

        /**
         * Converts this PermissionRecord to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        PermissionRecord.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for PermissionRecord
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.PermissionRecord
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        PermissionRecord.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.PermissionRecord";
        };

        return PermissionRecord;
    })();

    naturalcloudsyncv2.UpdateResponseMessage = (function() {

        /**
         * Properties of an UpdateResponseMessage.
         * @memberof naturalcloudsyncv2
         * @interface IUpdateResponseMessage
         * @property {number|null} [successRecCount] UpdateResponseMessage successRecCount
         */

        /**
         * Constructs a new UpdateResponseMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an UpdateResponseMessage.
         * @implements IUpdateResponseMessage
         * @constructor
         * @param {naturalcloudsyncv2.IUpdateResponseMessage=} [properties] Properties to set
         */
        function UpdateResponseMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * UpdateResponseMessage successRecCount.
         * @member {number} successRecCount
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @instance
         */
        UpdateResponseMessage.prototype.successRecCount = 0;

        /**
         * Creates a new UpdateResponseMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IUpdateResponseMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.UpdateResponseMessage} UpdateResponseMessage instance
         */
        UpdateResponseMessage.create = function create(properties) {
            return new UpdateResponseMessage(properties);
        };

        /**
         * Encodes the specified UpdateResponseMessage message. Does not implicitly {@link naturalcloudsyncv2.UpdateResponseMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IUpdateResponseMessage} message UpdateResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        UpdateResponseMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.successRecCount != null && Object.hasOwnProperty.call(message, "successRecCount"))
                writer.uint32(/* id 1, wireType 0 =*/8).int32(message.successRecCount);
            return writer;
        };

        /**
         * Encodes the specified UpdateResponseMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.UpdateResponseMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IUpdateResponseMessage} message UpdateResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        UpdateResponseMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an UpdateResponseMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.UpdateResponseMessage} UpdateResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        UpdateResponseMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.UpdateResponseMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.successRecCount = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an UpdateResponseMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.UpdateResponseMessage} UpdateResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        UpdateResponseMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an UpdateResponseMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        UpdateResponseMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.successRecCount != null && message.hasOwnProperty("successRecCount"))
                if (!$util.isInteger(message.successRecCount))
                    return "successRecCount: integer expected";
            return null;
        };

        /**
         * Creates an UpdateResponseMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.UpdateResponseMessage} UpdateResponseMessage
         */
        UpdateResponseMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.UpdateResponseMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.UpdateResponseMessage();
            if (object.successRecCount != null)
                message.successRecCount = object.successRecCount | 0;
            return message;
        };

        /**
         * Creates a plain object from an UpdateResponseMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {naturalcloudsyncv2.UpdateResponseMessage} message UpdateResponseMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        UpdateResponseMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults)
                object.successRecCount = 0;
            if (message.successRecCount != null && message.hasOwnProperty("successRecCount"))
                object.successRecCount = message.successRecCount;
            return object;
        };

        /**
         * Converts this UpdateResponseMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        UpdateResponseMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for UpdateResponseMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.UpdateResponseMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        UpdateResponseMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.UpdateResponseMessage";
        };

        return UpdateResponseMessage;
    })();

    naturalcloudsyncv2.QueryResponseMessage = (function() {

        /**
         * Properties of a QueryResponseMessage.
         * @memberof naturalcloudsyncv2
         * @interface IQueryResponseMessage
         * @property {number|null} [queryType] QueryResponseMessage queryType
         * @property {boolean|null} [isComplete] QueryResponseMessage isComplete
         * @property {naturalcloudsyncv2.IAggregateQueryResult|null} [aggQueryRes] QueryResponseMessage aggQueryRes
         */

        /**
         * Constructs a new QueryResponseMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a QueryResponseMessage.
         * @implements IQueryResponseMessage
         * @constructor
         * @param {naturalcloudsyncv2.IQueryResponseMessage=} [properties] Properties to set
         */
        function QueryResponseMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * QueryResponseMessage queryType.
         * @member {number} queryType
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @instance
         */
        QueryResponseMessage.prototype.queryType = 0;

        /**
         * QueryResponseMessage isComplete.
         * @member {boolean} isComplete
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @instance
         */
        QueryResponseMessage.prototype.isComplete = false;

        /**
         * QueryResponseMessage aggQueryRes.
         * @member {naturalcloudsyncv2.IAggregateQueryResult|null|undefined} aggQueryRes
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @instance
         */
        QueryResponseMessage.prototype.aggQueryRes = null;

        /**
         * Creates a new QueryResponseMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IQueryResponseMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.QueryResponseMessage} QueryResponseMessage instance
         */
        QueryResponseMessage.create = function create(properties) {
            return new QueryResponseMessage(properties);
        };

        /**
         * Encodes the specified QueryResponseMessage message. Does not implicitly {@link naturalcloudsyncv2.QueryResponseMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IQueryResponseMessage} message QueryResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        QueryResponseMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.queryType != null && Object.hasOwnProperty.call(message, "queryType"))
                writer.uint32(/* id 1, wireType 0 =*/8).int32(message.queryType);
            if (message.isComplete != null && Object.hasOwnProperty.call(message, "isComplete"))
                writer.uint32(/* id 2, wireType 0 =*/16).bool(message.isComplete);
            if (message.aggQueryRes != null && Object.hasOwnProperty.call(message, "aggQueryRes"))
                $root.naturalcloudsyncv2.AggregateQueryResult.encode(message.aggQueryRes, writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
            return writer;
        };

        /**
         * Encodes the specified QueryResponseMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.QueryResponseMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IQueryResponseMessage} message QueryResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        QueryResponseMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a QueryResponseMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.QueryResponseMessage} QueryResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        QueryResponseMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.QueryResponseMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.queryType = reader.int32();
                        break;
                    }
                case 2: {
                        message.isComplete = reader.bool();
                        break;
                    }
                case 3: {
                        message.aggQueryRes = $root.naturalcloudsyncv2.AggregateQueryResult.decode(reader, reader.uint32());
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a QueryResponseMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.QueryResponseMessage} QueryResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        QueryResponseMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a QueryResponseMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        QueryResponseMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.queryType != null && message.hasOwnProperty("queryType"))
                if (!$util.isInteger(message.queryType))
                    return "queryType: integer expected";
            if (message.isComplete != null && message.hasOwnProperty("isComplete"))
                if (typeof message.isComplete !== "boolean")
                    return "isComplete: boolean expected";
            if (message.aggQueryRes != null && message.hasOwnProperty("aggQueryRes")) {
                let error = $root.naturalcloudsyncv2.AggregateQueryResult.verify(message.aggQueryRes);
                if (error)
                    return "aggQueryRes." + error;
            }
            return null;
        };

        /**
         * Creates a QueryResponseMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.QueryResponseMessage} QueryResponseMessage
         */
        QueryResponseMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.QueryResponseMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.QueryResponseMessage();
            if (object.queryType != null)
                message.queryType = object.queryType | 0;
            if (object.isComplete != null)
                message.isComplete = Boolean(object.isComplete);
            if (object.aggQueryRes != null) {
                if (typeof object.aggQueryRes !== "object")
                    throw TypeError(".naturalcloudsyncv2.QueryResponseMessage.aggQueryRes: object expected");
                message.aggQueryRes = $root.naturalcloudsyncv2.AggregateQueryResult.fromObject(object.aggQueryRes);
            }
            return message;
        };

        /**
         * Creates a plain object from a QueryResponseMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {naturalcloudsyncv2.QueryResponseMessage} message QueryResponseMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        QueryResponseMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.queryType = 0;
                object.isComplete = false;
                object.aggQueryRes = null;
            }
            if (message.queryType != null && message.hasOwnProperty("queryType"))
                object.queryType = message.queryType;
            if (message.isComplete != null && message.hasOwnProperty("isComplete"))
                object.isComplete = message.isComplete;
            if (message.aggQueryRes != null && message.hasOwnProperty("aggQueryRes"))
                object.aggQueryRes = $root.naturalcloudsyncv2.AggregateQueryResult.toObject(message.aggQueryRes, options);
            return object;
        };

        /**
         * Converts this QueryResponseMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        QueryResponseMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for QueryResponseMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.QueryResponseMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        QueryResponseMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.QueryResponseMessage";
        };

        return QueryResponseMessage;
    })();

    naturalcloudsyncv2.AggregateQueryResult = (function() {

        /**
         * Properties of an AggregateQueryResult.
         * @memberof naturalcloudsyncv2
         * @interface IAggregateQueryResult
         * @property {boolean|null} [isNull] AggregateQueryResult isNull
         * @property {Long|null} [longRes] AggregateQueryResult longRes
         * @property {number|null} [doubleRes] AggregateQueryResult doubleRes
         */

        /**
         * Constructs a new AggregateQueryResult.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an AggregateQueryResult.
         * @implements IAggregateQueryResult
         * @constructor
         * @param {naturalcloudsyncv2.IAggregateQueryResult=} [properties] Properties to set
         */
        function AggregateQueryResult(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * AggregateQueryResult isNull.
         * @member {boolean} isNull
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @instance
         */
        AggregateQueryResult.prototype.isNull = false;

        /**
         * AggregateQueryResult longRes.
         * @member {Long|null|undefined} longRes
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @instance
         */
        AggregateQueryResult.prototype.longRes = null;

        /**
         * AggregateQueryResult doubleRes.
         * @member {number|null|undefined} doubleRes
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @instance
         */
        AggregateQueryResult.prototype.doubleRes = null;

        // OneOf field names bound to virtual getters and setters
        let $oneOfFields;

        /**
         * AggregateQueryResult result.
         * @member {"longRes"|"doubleRes"|undefined} result
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @instance
         */
        Object.defineProperty(AggregateQueryResult.prototype, "result", {
            get: $util.oneOfGetter($oneOfFields = ["longRes", "doubleRes"]),
            set: $util.oneOfSetter($oneOfFields)
        });

        /**
         * Creates a new AggregateQueryResult instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {naturalcloudsyncv2.IAggregateQueryResult=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.AggregateQueryResult} AggregateQueryResult instance
         */
        AggregateQueryResult.create = function create(properties) {
            return new AggregateQueryResult(properties);
        };

        /**
         * Encodes the specified AggregateQueryResult message. Does not implicitly {@link naturalcloudsyncv2.AggregateQueryResult.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {naturalcloudsyncv2.IAggregateQueryResult} message AggregateQueryResult message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        AggregateQueryResult.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.isNull != null && Object.hasOwnProperty.call(message, "isNull"))
                writer.uint32(/* id 1, wireType 0 =*/8).bool(message.isNull);
            if (message.longRes != null && Object.hasOwnProperty.call(message, "longRes"))
                writer.uint32(/* id 2, wireType 0 =*/16).int64(message.longRes);
            if (message.doubleRes != null && Object.hasOwnProperty.call(message, "doubleRes"))
                writer.uint32(/* id 3, wireType 1 =*/25).double(message.doubleRes);
            return writer;
        };

        /**
         * Encodes the specified AggregateQueryResult message, length delimited. Does not implicitly {@link naturalcloudsyncv2.AggregateQueryResult.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {naturalcloudsyncv2.IAggregateQueryResult} message AggregateQueryResult message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        AggregateQueryResult.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an AggregateQueryResult message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.AggregateQueryResult} AggregateQueryResult
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        AggregateQueryResult.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.AggregateQueryResult();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.isNull = reader.bool();
                        break;
                    }
                case 2: {
                        message.longRes = reader.int64();
                        break;
                    }
                case 3: {
                        message.doubleRes = reader.double();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an AggregateQueryResult message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.AggregateQueryResult} AggregateQueryResult
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        AggregateQueryResult.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an AggregateQueryResult message.
         * @function verify
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        AggregateQueryResult.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            let properties = {};
            if (message.isNull != null && message.hasOwnProperty("isNull"))
                if (typeof message.isNull !== "boolean")
                    return "isNull: boolean expected";
            if (message.longRes != null && message.hasOwnProperty("longRes")) {
                properties.result = 1;
                if (!$util.isInteger(message.longRes) && !(message.longRes && $util.isInteger(message.longRes.low) && $util.isInteger(message.longRes.high)))
                    return "longRes: integer|Long expected";
            }
            if (message.doubleRes != null && message.hasOwnProperty("doubleRes")) {
                if (properties.result === 1)
                    return "result: multiple values";
                properties.result = 1;
                if (typeof message.doubleRes !== "number")
                    return "doubleRes: number expected";
            }
            return null;
        };

        /**
         * Creates an AggregateQueryResult message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.AggregateQueryResult} AggregateQueryResult
         */
        AggregateQueryResult.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.AggregateQueryResult)
                return object;
            let message = new $root.naturalcloudsyncv2.AggregateQueryResult();
            if (object.isNull != null)
                message.isNull = Boolean(object.isNull);
            if (object.longRes != null)
                if ($util.Long)
                    (message.longRes = $util.Long.fromValue(object.longRes)).unsigned = false;
                else if (typeof object.longRes === "string")
                    message.longRes = parseInt(object.longRes, 10);
                else if (typeof object.longRes === "number")
                    message.longRes = object.longRes;
                else if (typeof object.longRes === "object")
                    message.longRes = new $util.LongBits(object.longRes.low >>> 0, object.longRes.high >>> 0).toNumber();
            if (object.doubleRes != null)
                message.doubleRes = Number(object.doubleRes);
            return message;
        };

        /**
         * Creates a plain object from an AggregateQueryResult message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {naturalcloudsyncv2.AggregateQueryResult} message AggregateQueryResult
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        AggregateQueryResult.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults)
                object.isNull = false;
            if (message.isNull != null && message.hasOwnProperty("isNull"))
                object.isNull = message.isNull;
            if (message.longRes != null && message.hasOwnProperty("longRes")) {
                if (typeof message.longRes === "number")
                    object.longRes = options.longs === String ? String(message.longRes) : message.longRes;
                else
                    object.longRes = options.longs === String ? $util.Long.prototype.toString.call(message.longRes) : options.longs === Number ? new $util.LongBits(message.longRes.low >>> 0, message.longRes.high >>> 0).toNumber() : message.longRes;
                if (options.oneofs)
                    object.result = "longRes";
            }
            if (message.doubleRes != null && message.hasOwnProperty("doubleRes")) {
                object.doubleRes = options.json && !isFinite(message.doubleRes) ? String(message.doubleRes) : message.doubleRes;
                if (options.oneofs)
                    object.result = "doubleRes";
            }
            return object;
        };

        /**
         * Converts this AggregateQueryResult to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        AggregateQueryResult.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for AggregateQueryResult
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.AggregateQueryResult
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        AggregateQueryResult.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.AggregateQueryResult";
        };

        return AggregateQueryResult;
    })();

    naturalcloudsyncv2.SubscribeResponseMessage = (function() {

        /**
         * Properties of a SubscribeResponseMessage.
         * @memberof naturalcloudsyncv2
         * @interface ISubscribeResponseMessage
         * @property {string|null} [subRecId] SubscribeResponseMessage subRecId
         * @property {string|null} [subId] SubscribeResponseMessage subId
         * @property {number|null} [subKey] SubscribeResponseMessage subKey
         * @property {number|null} [subResCode] SubscribeResponseMessage subResCode
         */

        /**
         * Constructs a new SubscribeResponseMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a SubscribeResponseMessage.
         * @implements ISubscribeResponseMessage
         * @constructor
         * @param {naturalcloudsyncv2.ISubscribeResponseMessage=} [properties] Properties to set
         */
        function SubscribeResponseMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * SubscribeResponseMessage subRecId.
         * @member {string} subRecId
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @instance
         */
        SubscribeResponseMessage.prototype.subRecId = "";

        /**
         * SubscribeResponseMessage subId.
         * @member {string} subId
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @instance
         */
        SubscribeResponseMessage.prototype.subId = "";

        /**
         * SubscribeResponseMessage subKey.
         * @member {number} subKey
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @instance
         */
        SubscribeResponseMessage.prototype.subKey = 0;

        /**
         * SubscribeResponseMessage subResCode.
         * @member {number} subResCode
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @instance
         */
        SubscribeResponseMessage.prototype.subResCode = 0;

        /**
         * Creates a new SubscribeResponseMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribeResponseMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.SubscribeResponseMessage} SubscribeResponseMessage instance
         */
        SubscribeResponseMessage.create = function create(properties) {
            return new SubscribeResponseMessage(properties);
        };

        /**
         * Encodes the specified SubscribeResponseMessage message. Does not implicitly {@link naturalcloudsyncv2.SubscribeResponseMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribeResponseMessage} message SubscribeResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SubscribeResponseMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.subRecId != null && Object.hasOwnProperty.call(message, "subRecId"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.subRecId);
            if (message.subId != null && Object.hasOwnProperty.call(message, "subId"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.subId);
            if (message.subKey != null && Object.hasOwnProperty.call(message, "subKey"))
                writer.uint32(/* id 3, wireType 0 =*/24).int32(message.subKey);
            if (message.subResCode != null && Object.hasOwnProperty.call(message, "subResCode"))
                writer.uint32(/* id 4, wireType 0 =*/32).int32(message.subResCode);
            return writer;
        };

        /**
         * Encodes the specified SubscribeResponseMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.SubscribeResponseMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribeResponseMessage} message SubscribeResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SubscribeResponseMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a SubscribeResponseMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.SubscribeResponseMessage} SubscribeResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SubscribeResponseMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.SubscribeResponseMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.subRecId = reader.string();
                        break;
                    }
                case 2: {
                        message.subId = reader.string();
                        break;
                    }
                case 3: {
                        message.subKey = reader.int32();
                        break;
                    }
                case 4: {
                        message.subResCode = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a SubscribeResponseMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.SubscribeResponseMessage} SubscribeResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SubscribeResponseMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a SubscribeResponseMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        SubscribeResponseMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.subRecId != null && message.hasOwnProperty("subRecId"))
                if (!$util.isString(message.subRecId))
                    return "subRecId: string expected";
            if (message.subId != null && message.hasOwnProperty("subId"))
                if (!$util.isString(message.subId))
                    return "subId: string expected";
            if (message.subKey != null && message.hasOwnProperty("subKey"))
                if (!$util.isInteger(message.subKey))
                    return "subKey: integer expected";
            if (message.subResCode != null && message.hasOwnProperty("subResCode"))
                if (!$util.isInteger(message.subResCode))
                    return "subResCode: integer expected";
            return null;
        };

        /**
         * Creates a SubscribeResponseMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.SubscribeResponseMessage} SubscribeResponseMessage
         */
        SubscribeResponseMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.SubscribeResponseMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.SubscribeResponseMessage();
            if (object.subRecId != null)
                message.subRecId = String(object.subRecId);
            if (object.subId != null)
                message.subId = String(object.subId);
            if (object.subKey != null)
                message.subKey = object.subKey | 0;
            if (object.subResCode != null)
                message.subResCode = object.subResCode | 0;
            return message;
        };

        /**
         * Creates a plain object from a SubscribeResponseMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.SubscribeResponseMessage} message SubscribeResponseMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        SubscribeResponseMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.subRecId = "";
                object.subId = "";
                object.subKey = 0;
                object.subResCode = 0;
            }
            if (message.subRecId != null && message.hasOwnProperty("subRecId"))
                object.subRecId = message.subRecId;
            if (message.subId != null && message.hasOwnProperty("subId"))
                object.subId = message.subId;
            if (message.subKey != null && message.hasOwnProperty("subKey"))
                object.subKey = message.subKey;
            if (message.subResCode != null && message.hasOwnProperty("subResCode"))
                object.subResCode = message.subResCode;
            return object;
        };

        /**
         * Converts this SubscribeResponseMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        SubscribeResponseMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for SubscribeResponseMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.SubscribeResponseMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        SubscribeResponseMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.SubscribeResponseMessage";
        };

        return SubscribeResponseMessage;
    })();

    naturalcloudsyncv2.UnsubscribeResponseMessage = (function() {

        /**
         * Properties of an UnsubscribeResponseMessage.
         * @memberof naturalcloudsyncv2
         * @interface IUnsubscribeResponseMessage
         * @property {string|null} [unSubRecId] UnsubscribeResponseMessage unSubRecId
         * @property {number|null} [unSubResCode] UnsubscribeResponseMessage unSubResCode
         */

        /**
         * Constructs a new UnsubscribeResponseMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents an UnsubscribeResponseMessage.
         * @implements IUnsubscribeResponseMessage
         * @constructor
         * @param {naturalcloudsyncv2.IUnsubscribeResponseMessage=} [properties] Properties to set
         */
        function UnsubscribeResponseMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * UnsubscribeResponseMessage unSubRecId.
         * @member {string} unSubRecId
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @instance
         */
        UnsubscribeResponseMessage.prototype.unSubRecId = "";

        /**
         * UnsubscribeResponseMessage unSubResCode.
         * @member {number} unSubResCode
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @instance
         */
        UnsubscribeResponseMessage.prototype.unSubResCode = 0;

        /**
         * Creates a new UnsubscribeResponseMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IUnsubscribeResponseMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.UnsubscribeResponseMessage} UnsubscribeResponseMessage instance
         */
        UnsubscribeResponseMessage.create = function create(properties) {
            return new UnsubscribeResponseMessage(properties);
        };

        /**
         * Encodes the specified UnsubscribeResponseMessage message. Does not implicitly {@link naturalcloudsyncv2.UnsubscribeResponseMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IUnsubscribeResponseMessage} message UnsubscribeResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        UnsubscribeResponseMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.unSubRecId != null && Object.hasOwnProperty.call(message, "unSubRecId"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.unSubRecId);
            if (message.unSubResCode != null && Object.hasOwnProperty.call(message, "unSubResCode"))
                writer.uint32(/* id 2, wireType 0 =*/16).int32(message.unSubResCode);
            return writer;
        };

        /**
         * Encodes the specified UnsubscribeResponseMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.UnsubscribeResponseMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.IUnsubscribeResponseMessage} message UnsubscribeResponseMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        UnsubscribeResponseMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an UnsubscribeResponseMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.UnsubscribeResponseMessage} UnsubscribeResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        UnsubscribeResponseMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.UnsubscribeResponseMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.unSubRecId = reader.string();
                        break;
                    }
                case 2: {
                        message.unSubResCode = reader.int32();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an UnsubscribeResponseMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.UnsubscribeResponseMessage} UnsubscribeResponseMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        UnsubscribeResponseMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an UnsubscribeResponseMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        UnsubscribeResponseMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.unSubRecId != null && message.hasOwnProperty("unSubRecId"))
                if (!$util.isString(message.unSubRecId))
                    return "unSubRecId: string expected";
            if (message.unSubResCode != null && message.hasOwnProperty("unSubResCode"))
                if (!$util.isInteger(message.unSubResCode))
                    return "unSubResCode: integer expected";
            return null;
        };

        /**
         * Creates an UnsubscribeResponseMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.UnsubscribeResponseMessage} UnsubscribeResponseMessage
         */
        UnsubscribeResponseMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.UnsubscribeResponseMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.UnsubscribeResponseMessage();
            if (object.unSubRecId != null)
                message.unSubRecId = String(object.unSubRecId);
            if (object.unSubResCode != null)
                message.unSubResCode = object.unSubResCode | 0;
            return message;
        };

        /**
         * Creates a plain object from an UnsubscribeResponseMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {naturalcloudsyncv2.UnsubscribeResponseMessage} message UnsubscribeResponseMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        UnsubscribeResponseMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.unSubRecId = "";
                object.unSubResCode = 0;
            }
            if (message.unSubRecId != null && message.hasOwnProperty("unSubRecId"))
                object.unSubRecId = message.unSubRecId;
            if (message.unSubResCode != null && message.hasOwnProperty("unSubResCode"))
                object.unSubResCode = message.unSubResCode;
            return object;
        };

        /**
         * Converts this UnsubscribeResponseMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        UnsubscribeResponseMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for UnsubscribeResponseMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.UnsubscribeResponseMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        UnsubscribeResponseMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.UnsubscribeResponseMessage";
        };

        return UnsubscribeResponseMessage;
    })();

    naturalcloudsyncv2.SubscribePushMessage = (function() {

        /**
         * Properties of a SubscribePushMessage.
         * @memberof naturalcloudsyncv2
         * @interface ISubscribePushMessage
         * @property {string|null} [subRecId] SubscribePushMessage subRecId
         * @property {Long|null} [pushSeq] SubscribePushMessage pushSeq
         * @property {number|null} [subKey] SubscribePushMessage subKey
         * @property {string|null} [subId] SubscribePushMessage subId
         */

        /**
         * Constructs a new SubscribePushMessage.
         * @memberof naturalcloudsyncv2
         * @classdesc Represents a SubscribePushMessage.
         * @implements ISubscribePushMessage
         * @constructor
         * @param {naturalcloudsyncv2.ISubscribePushMessage=} [properties] Properties to set
         */
        function SubscribePushMessage(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * SubscribePushMessage subRecId.
         * @member {string} subRecId
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @instance
         */
        SubscribePushMessage.prototype.subRecId = "";

        /**
         * SubscribePushMessage pushSeq.
         * @member {Long} pushSeq
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @instance
         */
        SubscribePushMessage.prototype.pushSeq = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * SubscribePushMessage subKey.
         * @member {number} subKey
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @instance
         */
        SubscribePushMessage.prototype.subKey = 0;

        /**
         * SubscribePushMessage subId.
         * @member {string} subId
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @instance
         */
        SubscribePushMessage.prototype.subId = "";

        /**
         * Creates a new SubscribePushMessage instance using the specified properties.
         * @function create
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribePushMessage=} [properties] Properties to set
         * @returns {naturalcloudsyncv2.SubscribePushMessage} SubscribePushMessage instance
         */
        SubscribePushMessage.create = function create(properties) {
            return new SubscribePushMessage(properties);
        };

        /**
         * Encodes the specified SubscribePushMessage message. Does not implicitly {@link naturalcloudsyncv2.SubscribePushMessage.verify|verify} messages.
         * @function encode
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribePushMessage} message SubscribePushMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SubscribePushMessage.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.subRecId != null && Object.hasOwnProperty.call(message, "subRecId"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.subRecId);
            if (message.pushSeq != null && Object.hasOwnProperty.call(message, "pushSeq"))
                writer.uint32(/* id 2, wireType 0 =*/16).int64(message.pushSeq);
            if (message.subKey != null && Object.hasOwnProperty.call(message, "subKey"))
                writer.uint32(/* id 3, wireType 0 =*/24).int32(message.subKey);
            if (message.subId != null && Object.hasOwnProperty.call(message, "subId"))
                writer.uint32(/* id 4, wireType 2 =*/34).string(message.subId);
            return writer;
        };

        /**
         * Encodes the specified SubscribePushMessage message, length delimited. Does not implicitly {@link naturalcloudsyncv2.SubscribePushMessage.verify|verify} messages.
         * @function encodeDelimited
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {naturalcloudsyncv2.ISubscribePushMessage} message SubscribePushMessage message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        SubscribePushMessage.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a SubscribePushMessage message from the specified reader or buffer.
         * @function decode
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {naturalcloudsyncv2.SubscribePushMessage} SubscribePushMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SubscribePushMessage.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.naturalcloudsyncv2.SubscribePushMessage();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.subRecId = reader.string();
                        break;
                    }
                case 2: {
                        message.pushSeq = reader.int64();
                        break;
                    }
                case 3: {
                        message.subKey = reader.int32();
                        break;
                    }
                case 4: {
                        message.subId = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a SubscribePushMessage message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {naturalcloudsyncv2.SubscribePushMessage} SubscribePushMessage
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        SubscribePushMessage.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a SubscribePushMessage message.
         * @function verify
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        SubscribePushMessage.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.subRecId != null && message.hasOwnProperty("subRecId"))
                if (!$util.isString(message.subRecId))
                    return "subRecId: string expected";
            if (message.pushSeq != null && message.hasOwnProperty("pushSeq"))
                if (!$util.isInteger(message.pushSeq) && !(message.pushSeq && $util.isInteger(message.pushSeq.low) && $util.isInteger(message.pushSeq.high)))
                    return "pushSeq: integer|Long expected";
            if (message.subKey != null && message.hasOwnProperty("subKey"))
                if (!$util.isInteger(message.subKey))
                    return "subKey: integer expected";
            if (message.subId != null && message.hasOwnProperty("subId"))
                if (!$util.isString(message.subId))
                    return "subId: string expected";
            return null;
        };

        /**
         * Creates a SubscribePushMessage message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {naturalcloudsyncv2.SubscribePushMessage} SubscribePushMessage
         */
        SubscribePushMessage.fromObject = function fromObject(object) {
            if (object instanceof $root.naturalcloudsyncv2.SubscribePushMessage)
                return object;
            let message = new $root.naturalcloudsyncv2.SubscribePushMessage();
            if (object.subRecId != null)
                message.subRecId = String(object.subRecId);
            if (object.pushSeq != null)
                if ($util.Long)
                    (message.pushSeq = $util.Long.fromValue(object.pushSeq)).unsigned = false;
                else if (typeof object.pushSeq === "string")
                    message.pushSeq = parseInt(object.pushSeq, 10);
                else if (typeof object.pushSeq === "number")
                    message.pushSeq = object.pushSeq;
                else if (typeof object.pushSeq === "object")
                    message.pushSeq = new $util.LongBits(object.pushSeq.low >>> 0, object.pushSeq.high >>> 0).toNumber();
            if (object.subKey != null)
                message.subKey = object.subKey | 0;
            if (object.subId != null)
                message.subId = String(object.subId);
            return message;
        };

        /**
         * Creates a plain object from a SubscribePushMessage message. Also converts values to other types if specified.
         * @function toObject
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {naturalcloudsyncv2.SubscribePushMessage} message SubscribePushMessage
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        SubscribePushMessage.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.defaults) {
                object.subRecId = "";
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.pushSeq = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.pushSeq = options.longs === String ? "0" : 0;
                object.subKey = 0;
                object.subId = "";
            }
            if (message.subRecId != null && message.hasOwnProperty("subRecId"))
                object.subRecId = message.subRecId;
            if (message.pushSeq != null && message.hasOwnProperty("pushSeq"))
                if (typeof message.pushSeq === "number")
                    object.pushSeq = options.longs === String ? String(message.pushSeq) : message.pushSeq;
                else
                    object.pushSeq = options.longs === String ? $util.Long.prototype.toString.call(message.pushSeq) : options.longs === Number ? new $util.LongBits(message.pushSeq.low >>> 0, message.pushSeq.high >>> 0).toNumber() : message.pushSeq;
            if (message.subKey != null && message.hasOwnProperty("subKey"))
                object.subKey = message.subKey;
            if (message.subId != null && message.hasOwnProperty("subId"))
                object.subId = message.subId;
            return object;
        };

        /**
         * Converts this SubscribePushMessage to JSON.
         * @function toJSON
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        SubscribePushMessage.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for SubscribePushMessage
         * @function getTypeUrl
         * @memberof naturalcloudsyncv2.SubscribePushMessage
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        SubscribePushMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/naturalcloudsyncv2.SubscribePushMessage";
        };

        return SubscribePushMessage;
    })();

    return naturalcloudsyncv2;
})();

export { $root as default };
