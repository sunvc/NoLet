/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { DatabaseException } from '../DatabaseException';
import { ErrorCode } from './ErrorCode';

const TAG = 'BasicException';

/**
 * This class is used to parse the specific code to error message,
 * stacktrace and check the exception code, don't throw it directly.
 */
export class BasicException {
  private static readonly ErrorMessageMapper = new Map([
    [ErrorCode.OK, ''],
    [ErrorCode.INTERNAL_ERROR, 'internal error.'],
    [ErrorCode.CLOUDDBZONE_INIT_FAILED, 'CloudDBZone init failed.'],
    [ErrorCode.CLOUDDBZONE_DOES_NOT_EXIST, 'CloudDBZone does not exist.'],
    [ErrorCode.CLOUDDBZONE_NUM_EXCEEDS_LIMIT, 'the count of CloudDBZone exceeds the limit.'],
    [ErrorCode.CLOUDDBZONE_IS_BUSY, 'CloudDBZone is busy.'],
    [ErrorCode.CLOUDDBZONE_IS_OPENED, 'please close CloudDBZone first.'],
    [ErrorCode.CLOUDDBZONE_IS_CLOSED, 'please open CloudDBZone first.'],
    [ErrorCode.SUBSCRIBER_IS_REGISTERED, 'please remove subscriber first.'],
    [ErrorCode.QUERY_POLICY_IS_ILLEGAL, 'query policy is illegal.'],
    [ErrorCode.SNAPSHOT_NUM_EXCEEDS_LIMIT, 'the count of snapshot exceeds the limit.'],
    [ErrorCode.SDK_VERSION_COLLAPSE, 'sdk version error.'],
    [ErrorCode.LOCAL_PERMISSION_DENIED, 'permission denied.'],
    [ErrorCode.OBJECT_TYPE_NO_EXIST, 'object type does not exist.'],
    [ErrorCode.OBJECT_TYPE_INFO_IS_INVALID, 'object type info is invalid.'],
    [ErrorCode.CLOUDDBCONFIG_INVALID, 'CloudDBZone config is invalid.'],
    [ErrorCode.NO_DATA_FOUND, 'no data was found in CloudDBZone.'],
    [ErrorCode.TRANSFER_UNFINISHED, 'transfer data is unfinished.'],
    [ErrorCode.OBJECTTYPE_VERSION_NOT_ALLOW_DOWNGRADE, 'downgrade object type version is illegal.'],
    [ErrorCode.USER_KEY_INVALID, 'user key is invalid.'],
    [ErrorCode.DATA_ENCRYPTION_KEY_INVALID, 'data encryption key is invalid.'],
    [ErrorCode.ENCRYPT_FAILED, 'encrypt failed.'],
    [ErrorCode.DECRYPT_FAILED, 'decrypt failed.'],
    [ErrorCode.ENCRYPTION_SALT_EMPTY, 'please set user key first.'],

    [ErrorCode.NETWORK_UNAVAILABLE, 'Connect to server failed.'],
    [ErrorCode.SCHEMA_NEGOTIATING, 'Object type negotiating.'],
    [ErrorCode.SCHEMA_NEGOTIATE_FAIL, 'Object type negotiation exception.'],
    [ErrorCode.INPUT_PARAMETER_INVALID, 'Internal error.'],
    [ErrorCode.COMMUNICATOR_QUEUE_FULL, 'Internal error.'],
    [ErrorCode.COMMUNICATOR_UNINITIALIZED, 'Connect to server failed.'],
    [ErrorCode.COMMUNICATOR_DATA_LENGTH_INVALID, 'Internal error.'],
    [ErrorCode.SYNC_TASK_NO_RESPONSE, 'Request timeout.'],
    [ErrorCode.SYNC_REQUEST_GENERATE_FAIL, 'Internal error.'],
    [ErrorCode.SYNC_RESPONSE_PARSE_FAIL, 'Internal error.'],
    [ErrorCode.SYNC_RESPONSE_CONTENT_ILLEGAL, 'Internal error.'],
    [ErrorCode.GATE_COMM_OVER_TIME, 'Request failed.'],
    [ErrorCode.CLIENT_TOKEN_REQUEST_FAIL, 'Get verify info failed.'],
    [ErrorCode.USER_INFO_REQUEST_ERROR, 'Get verify info failed.'],
    [ErrorCode.INVALID_APP_CONTEXT, 'Illegal application context.'],

    [ErrorCode.VERIFY_TOKEN_FAILED, 'verify token failed.'],
    [ErrorCode.SYNC_PERMISSION_DENY, 'permission denied.'],
    [ErrorCode.PRODUCT_SUB_COUNT_OVER_LIMIT, 'the count of product subscriber exceeds the limit.'],
    [ErrorCode.CLIENT_SUB_COUNT_OVER_LIMIT, 'the count of client subscriber exceeds the limit.'],
    [
      ErrorCode.SUB_CONDITION_OVER_COUNT,
      'the count of condition for subscription exceeds the limit.'
    ],
    [ErrorCode.SUB_CONDITION_TYPE_NOT_SUPPORT, 'unsupported subscription condition type.'],
    [ErrorCode.SUB_FIELD_TYPE_NOT_SUPPORT, 'unsupported subscription field type.'],
    [
      ErrorCode.SUB_FIELD_VALUE_LEN_OVER_LIMIT,
      'the length of subscription field value exceeds the limit.'
    ],
    [
      ErrorCode.TRANSACTION_RECORD_COUNT_OVER_LIMIT,
      'the count of transaction record exceeds the limit.'
    ],
    [
      ErrorCode.INDEX_NOT_FOUND,
      '"query %s with pagination from the cloud database failed: %s no such index for query.'
    ],
    [
      ErrorCode.SUB_NOT_SUPPORT_OBJECT_TYPE,
      'subscription condition objectType contains autoIncrement field.'
    ],
    [ErrorCode.SUB_SENSITIVE_FIELD_NOT_SUPPORT, 'sensitive fields do not support subscription.'],
    [ErrorCode.SYNC_INVALID_PARAM, 'execution parameter is illegal.'],
    [ErrorCode.SYNC_INVALID_STORE, 'execution parameter is illegal.'],
    [ErrorCode.SYNC_INVALID_FIELD, 'execution parameter is illegal.'],
    [ErrorCode.SYNC_INVALID_FIELD_TYPE, 'illegal subscription condition.'],
    [ErrorCode.SYNC_INVALID_PRODUCT, 'internal error.'],
    [ErrorCode.SYNC_INVALID_QUERY_CONDITION, 'sensitive field not support this query condition.'],
    [ErrorCode.SUB_ADD_INTERNAL_ERROR, 'internal error.'],
    [ErrorCode.ILLEGAL_STORE_QUERY_RETURN, 'internal error.'],
    [ErrorCode.SYNC_MSG_SERIALIZATION_ERROR, 'internal error.'],
    [ErrorCode.PRODUCT_ARREARS, 'product arrears.'],
    [ErrorCode.READ_QUOTA_INSUFFICIENT, 'insufficient read quota.'],
    [ErrorCode.WRITE_QUOTA_INSUFFICIENT, 'insufficient write quota.'],
    [ErrorCode.DELETE_QUOTA_INSUFFICIENT, 'insufficient delete quota.'],
    [ErrorCode.NETWORK_QUOTA_INSUFFICIENT, 'insufficient network quota.'],
    [ErrorCode.STORAGE_QUOTA_INSUFFICIENT, 'insufficient storage quota.'],
    [ErrorCode.DB_WRITE_OVER_LIMIT, 'resources are exhausted.'],
    [ErrorCode.OPS_OVER_LIMIT, 'resources are exhausted.'],
    [ErrorCode.SYNC_THREAD_POOL_REJECTED, 'resources are exhausted.'],
    [ErrorCode.USER_READ_QUOTA_OVER_LIMIT, 'resources are exhausted.'],
    [ErrorCode.USER_UPSERT_QUOTA_OVER_LIMIT, 'resources are exhausted.'],
    [ErrorCode.USER_DELET_QUOTA_OVER_LIMIT, 'resources are exhausted.'],
    [ErrorCode.USER_OUT_BUFFER_QUOTA_OVER_LIMIT, 'resources are exhausted.'],
    [
      ErrorCode.ENCRYPT_RECORD_EMPTY,
      'the system status does not meet the operation execution conditions.'
    ],
    [ErrorCode.ENCRYPTION_VERSION_UNMATCHED, 'invalid operation argument.'],
    [ErrorCode.ENCRYPT_RE_KEY_REJECT, 'rejected by data re-encrypting.'],
    [ErrorCode.RE_KEY_STATUS_ERROR, 'illegal request.'],
    [ErrorCode.RE_KEY_MSG_ERROR, 'illegal request.'],
    [ErrorCode.INVALID_INPUT_SCHEMA, 'object type is empty.'],
    [ErrorCode.INVALID_SCHEMA_NAME, 'object type is not found.'],
    [ErrorCode.SCHEMA_FIELDS_COUNT_UNMATCHED, 'the count of object type field mismatched.'],
    [ErrorCode.SCHEMA_FIELDS_LOST, 'object type field mismatched.'],
    [ErrorCode.SCHEMA_FIELDS_TYPE_UNMATCHED, 'the type of object type field mismatched.'],
    [
      ErrorCode.SCHEMA_FIELDS_NULL_TYPE_UNMATCHED,
      'the null property of object type field mismatched.'
    ],
    [
      ErrorCode.SCHEMA_FIELDS_PRIMARY_KEY_UNMATCHED,
      'the primary key of object type field mismatched.'
    ],
    [
      ErrorCode.SCHEMA_FIELDS_DEFAULT_VALUE_UNMATCHED,
      'the default value of object type field mismatched.'
    ],
    [
      ErrorCode.SCHEMA_FIELDS_ENCRYPT_UNMATCHED,
      'the encryption property of object type field mismatched.'
    ],

    [ErrorCode.SYSTEM_ERROR, 'system error.'],
    [ErrorCode.OPERATION_ILLEGAL, 'operation is illegal.'],
    [ErrorCode.PRODUCT_STATUS_NON_CREATED, 'product status is not created.'],
    [ErrorCode.DB_ZONE_EXCEED_LIMIT, 'the count of DB Zones exceeds the limit.'],
    [ErrorCode.SCHEMA_DELETE_NOT_ALLOWED, 'object type is not allowed to delete.'],
    [
      ErrorCode.SCHEMA_MODIFY_NOT_ALLOWED_ON_IMPORT,
      'object type is not allowed to modify while import.'
    ],
    [ErrorCode.SCHEMA_COUNT_EXCEED_LIMIT, 'the count of object type exceeds the limit.'],
    [ErrorCode.PRIMARY_KEY_MODIFY_NOT_ALLOWED, 'primary key is not allowed to modify.'],
    [ErrorCode.FIELD_MODIFY_NOT_ALLOWED, 'the field is not allowed to modify.'],
    [ErrorCode.FIELD_DELETE_NOT_ALLOWED, 'the field is not allowed to delete.'],
    [ErrorCode.FIELD_COUNT_EXCEED_LIMIT, 'the count of field exceeds the limit.'],
    [ErrorCode.INDEX_MODIFY_NOT_ALLOWED, 'the index is not allowed to modify.'],
    [ErrorCode.INDEX_DELETE_NOT_ALLOWED, 'the index is not allowed to delete.'],
    [ErrorCode.INDEX_COUNT_EXCEED_LIMIT, 'the count of index exceeds the limit.'],
    [ErrorCode.INDEX_FIELD_COUNT_EXCEED_LIMIT, 'the count of fields in a index exceeds the limit.'],
    [ErrorCode.PERMISSION_NOT_FOUND, 'no permission found.'],
    [ErrorCode.PERMISSION_DENIED, 'permission denied.'],
    [ErrorCode.QUERY_ENCRYPTED_FIELD_UNSUPPORTED, 'encrypted field does not support this query.'],
    [ErrorCode.QUERY_RESULT_SIZE_EXCEED_LIMIT, 'the capacity of objects exceeds the limit.'],
    [ErrorCode.QUERY_RESULT_COUNT_EXCEED_LIMIT, 'the size of object list exceeds the limit.'],
    [ErrorCode.WRITE_PROHIBITED, 'write is prohibited.'],
    [
      ErrorCode.WRITE_VALUE_SIZE_EXCEED_LIMIT,
      'the size of the data to be written exceeds the limit.'
    ],
    [
      ErrorCode.WRITE_STRING_VALUE_SIZE_EXCEED_LIMIT,
      'the size of a string data to be written exceeds the limit.'
    ],
    [ErrorCode.ENCRYPTION_USER_NOT_FOUND, 'operation is illegal.'],
    [ErrorCode.ENCRYPTION_USER_DUPLICATE, 'operation is illegal.'],
    [ErrorCode.ENCRYPTION_FAILURE_OVER_TIMES, 'user is locked.'],
    [ErrorCode.ENCRYPTION_TOKEN_UNMATCHED, 'user authentication failed.'],
    [
      ErrorCode.ENCRYPTION_OPERATION_DENIED_STATUS_ABNORMAL,
      'the service is unavailable currently.'
    ],
    [
      ErrorCode.ENCRYPTION_OPERATION_DENIED_STATUS_UPDATING,
      'operation is denied while key is updating.'
    ],
    [ErrorCode.FIELD_STRING_COUNT_EXCEED_LIMIT, 'the count of string field exceeds the limit.'],
    [ErrorCode.READ_PROHIBITED, 'read is prohibited.'],
    [ErrorCode.QUERY_SENSITIVE_FIELD_UNSUPPORTED, 'sensitive field does not support this query.'],
    [ErrorCode.PARAM_INVALID, 'invalid parameter.'],
    [ErrorCode.PRODUCT_ID_INVALID, 'product id is invalid.'],
    [ErrorCode.PRODUCT_TYPE_INVALID, 'product type is invalid.'],
    [ErrorCode.STORE_ID_INVALID, 'store id is invalid.'],
    [ErrorCode.SCHEMA_OPERATION_UNSUPPORTED, 'unsupported operation for object type.'],
    [ErrorCode.SCHEMA_ORIGINAL_CHANGED, 'original object type is changed.'],
    [ErrorCode.SCHEMA_EXISTED, 'object type already exists.'],
    [ErrorCode.SCHEMA_NOT_EXIST, 'object type does not exist.'],
    [ErrorCode.SCHEMA_DUPLICATE, 'object type is duplicate.'],
    [ErrorCode.SCHEMA_NAME_INVALID, 'object type name is invalid.'],
    [ErrorCode.SCHEMA_NO_FIELD, 'no field in the object type.'],
    [ErrorCode.SCHEMA_INVALID, 'object type is invalid.'],
    [ErrorCode.FIELD_DUPLICATE, 'field name is duplicate.'],
    [ErrorCode.FIELD_NAME_INVALID, 'field name is invalid.'],
    [ErrorCode.FIELD_TYPE_INVALID, 'field type is invalid.'],
    [ErrorCode.FIELD_VALUE_INVALID, 'field value is invalid.'],
    [ErrorCode.ENCRYPTED_FIELD_VALUE_TYPE_ERROR, 'encrypt field type error.'],
    [ErrorCode.INDEX_NAME_INVALID, 'index name is invalid.'],
    [ErrorCode.INDEX_DUPLICATE, 'index name is duplicate.'],
    [ErrorCode.INDEX_FIELD_NOT_EXIST, 'field in an index does not exist.'],
    [ErrorCode.ROLE_TYPE_INVALID, 'role type is invalid.'],
    [ErrorCode.CURSOR_INDEX_INVALID, 'index is invalid while query by cursor.'],
    [ErrorCode.CACHE_CHANGE_MESSAGE_INVALID, 'invalid cache-changed message.'],
    [ErrorCode.USER_INPUT_INVALID, 'invalid input.'],
    [ErrorCode.DEFAULT_VALUE_ABSENT, 'default value is absent.'],
    [ErrorCode.PRIMARY_KEY_NOT_SET_NOT_NULL, 'primary key does not set not null.'],
    [
      ErrorCode.PRIMARY_KEY_NOT_SUPPORT_DEFAULT_VALUE,
      'primary key does not support setting default value.'
    ],
    [
      ErrorCode.PRIMARY_KEY_NOT_SUPPORT_ENCRYPTED,
      'primary key does not support setting encrypted.'
    ],
    [ErrorCode.PRIMARY_KEY_NOT_SUPPORT_CURRENT_TYPE, 'primary key does not support the type.'],
    [ErrorCode.PRIMARY_KEY_ABSENT, 'primary key can not be found.'],
    [ErrorCode.PRIMARY_KEY_NUMBER_EXCEED, 'the count of primary key exceeds the limit.'],
    [ErrorCode.FILED_TYPE_NOT_SUPPORT_NOT_NULL, 'filed type does not support setting not null.'],
    [
      ErrorCode.FILED_TYPE_NOT_SUPPORT_DEFAULT_VALUE,
      'filed type does not support setting default value.'
    ],
    [ErrorCode.FILED_TYPE_NOT_SUPPORT_ENCRYPT, 'filed type does not support setting encrypt.'],
    [
      ErrorCode.SCHEMA_CONCURRENT_MODIFY_ERROR,
      'object type does not support modifying concurrently.'
    ],
    [ErrorCode.DEFAULT_VALUE_MUST_NOT_NULL, 'field of default value can not set as null.'],
    [ErrorCode.NOT_NULL_FIELD_IS_NULL, 'not null field can not be null.'],
    [ErrorCode.DB_ZONE_NOT_EXIST, 'CloudDBZone does not exist.'],
    [
      ErrorCode.PRIMARY_KEY_NOT_SUPPORT_SENSITIVE,
      'primary key does not support setting sensitive.'
    ],
    [ErrorCode.FIELD_TYPE_NOT_SUPPORT_SENSITIVE, 'field type does not support setting sensitive.'],
    [ErrorCode.INDEX_CONTAINS_SENSITIVE_FIELD, 'the index cannot contain sensitive field.'],
    [
      ErrorCode.SENSITIVE_FIELD_NOT_SUPPORT_INCREMENT,
      'sensitive field not support increment operation.'
    ],
    [
      ErrorCode.SCHEMA_WITH_SENSITIVE_FIELD_UNSUPPORTED_THIS_OPERATION,
      'schema with sensitive field not support this operation.'
    ],
    [ErrorCode.RUNTIME_ERROR, 'runtime error.'],
    [ErrorCode.STORAGE_USAGE_GET_ERROR, 'getting usage of the storage failed.'],
    [ErrorCode.STORAGE_SIZE_GET_ERROR, 'getting size of the storage failed.'],
    [ErrorCode.APP_CREATE_ERROR, 'creating app failed.'],
    [ErrorCode.APP_DELETE_ERROR, 'deleting app failed.'],
    [ErrorCode.DATABASE_CREATE_ERROR, 'creating database failed.'],
    [
      ErrorCode.DATABASE_CHECK_EXIST_ERROR,
      'error occurred while checking the existence of a database instance.'
    ],
    [ErrorCode.NODE_GROUP_OCCUPY_ERROR, 'occupying node group failed.'],
    [ErrorCode.NODE_GROUP_FREE_ERROR, 'freeing node group failed.'],
    [ErrorCode.PGXC_NODE_QUERY_ERROR, 'querying node information failed.'],
    [
      ErrorCode.PRODUCT_TO_NODE_GROUP_QUERY_ERROR,
      'querying the mapping between products and node groups failed.'
    ],
    [ErrorCode.CLUSTER_INFO_QUERY_ALL_ERROR, 'querying the products in cluster failed.'],
    [ErrorCode.CLUSTER_GET_AVAILABLE_ERROR, 'querying available clusters failed.'],
    [ErrorCode.CLUSTER_OCCUPY_ERROR, 'occupying cluster failed.'],
    [ErrorCode.CLUSTER_QUERY_ERROR, 'querying cluster failed.'],
    [ErrorCode.DB_MAPPER_CONFIG_INSERT_ERROR, 'inserting config of product mapping failed.'],
    [
      ErrorCode.DB_ZONE_CHECK_EXIST_ERROR,
      'error occurred while checking the existence of a DB zone.'
    ],
    [ErrorCode.DB_ZONE_CREATE_ERROR, 'creating DB zone failed.'],
    [ErrorCode.DB_ZONE_DROP_ERROR, 'dropping DB zone failed.'],
    [ErrorCode.SYSTEM_TABLE_INIT_ERROR, 'initializing system tables failed.'],
    [ErrorCode.SCHEMA_UPGRADE_ERROR, 'upgrading schema failed.'],
    [ErrorCode.SCHEMA_VERSION_GENERATE_ERROR, 'generating a new schema version failed.'],
    [ErrorCode.SCHEMA_PERMISSION_SET_ERROR, 'setting permission for schemas failed.'],
    [ErrorCode.FIELD_TYPE_ERROR, 'field type error.'],
    [ErrorCode.TABLE_CREATE_ERROR, 'creating table failed.'],
    [ErrorCode.TABLE_UPGRADE_ERROR, 'upgrading table failed.'],
    [ErrorCode.TABLE_DROP_ERROR, 'dropping object type failed.'],
    [ErrorCode.TABLE_CHECK_EXIST_ERROR, 'error occurred while checking the existence of a table.'],
    [ErrorCode.TABLE_LOCK_ERROR, 'locking table failed.'],
    [ErrorCode.PRODUCT_MAPPING_QUERY_ERROR, 'querying product mapping failed.'],
    [ErrorCode.PRODUCT_MAPPING_UPSERT_ERROR, 'upserting product mapping failed.'],
    [ErrorCode.PRODUCT_MAPPING_DELETE_ERROR, 'deleting product mapping failed.'],
    [ErrorCode.PRODUCT_KEY_QUERY_ERROR, 'querying product key failed.'],
    [ErrorCode.PRODUCT_KEY_INSERT_ERROR, 'inserting product key failed.'],
    [ErrorCode.PRODUCT_KEY_DELETE_ERROR, 'deleting product key failed.'],
    [ErrorCode.PRODUCT_STATUS_QUERY_ERROR, 'querying product status failed.'],
    [ErrorCode.PRODUCT_STATUS_UPDATE_ERROR, 'updating product status failed.'],
    [ErrorCode.PRODUCT_INFO_QUERY_ALL_ERROR, 'querying all the products failed.'],
    [ErrorCode.PRODUCT_INFO_PERSIST_ERROR, 'saving product info failed.'],
    [ErrorCode.PRODUCT_INFO_DELETE_ERROR, 'deleting product info failed.'],
    [ErrorCode.PRODUCT_DB_ID_QUERY_ERROR, 'querying the mapping between product and DB ID failed.'],
    [ErrorCode.PRODUCT_ID_QUERY_ALL_ERROR, 'querying all IDs of the products failed.'],
    [ErrorCode.ID_GENERATE_ERROR, 'generate ID failed.'],
    [ErrorCode.ID_LOCK_ERROR, 'locking the ID failed.'],
    [ErrorCode.ID_VALUE_TYPE_ERROR, 'value type of the ID is incorrect.'],
    [ErrorCode.ID_UPDATE_ERROR, 'updating ID failed.'],
    [ErrorCode.COUNTER_INIT_ERROR, 'initializing counter failed.'],
    [ErrorCode.COUNTER_QUERY_ERROR, 'querying counter failed.'],
    [ErrorCode.COUNTER_UPDATE_ERROR, 'update counter failed.'],
    [ErrorCode.CACHED_PLAN_CHANGED, 'cached plan changed.'],
    [ErrorCode.PREPARED_STATEMENT_INVALID, 'invalid prepared statement.'],
    [ErrorCode.BIND_VALUE_ERROR, 'bind value to statement failed.'],
    [ErrorCode.VALUE_CONVERT_ERROR, 'value convert failed.'],
    [ErrorCode.NUMERIC_VALUE_OUT_OF_RANGE_ERROR, 'numeric value out of range.'],
    [ErrorCode.DB_CONNECTION_GET_ERROR, 'getting DB connection failed.'],
    [ErrorCode.DB_CONNECTION_INIT_ERROR, 'initializing DB connection failed.'],
    [ErrorCode.DB_CONNECTION_INVALID, 'invalid DB connection.'],
    [ErrorCode.DB_GROUP_ID_NOT_FOUND, 'invalid group id for DB.'],
    [ErrorCode.USE_DATABASE_ERROR, 'use database for connection failed.'],
    [ErrorCode.DB_MAPPER_CONFIG_VERIFY_ERROR, 'verifying the config of product mapping failed.'],
    [ErrorCode.CONFIG_IN_DB_GET_ERROR, 'getting config in DB failed.'],
    [ErrorCode.CONFIG_IN_DB_MODIFY_ERROR, 'modifying config in DB failed.'],
    [ErrorCode.CONFIG_IN_DB_ITEM_NOT_EXIST, 'item does not exist in config.'],
    [ErrorCode.TRANSACTION_EXECUTE_ERROR, 'transaction execute failed.'],
    [ErrorCode.TRANSACTION_START_ERROR, 'transaction start failed.'],
    [ErrorCode.TRANSACTION_COMMIT_ERROR, 'transaction commit failed.'],
    [ErrorCode.TRANSACTION_ROLLBACK_ERROR, 'transaction rollback failed.'],
    [ErrorCode.SQL_EXECUTE_ERROR, 'sql execute failed.'],
    [ErrorCode.QUERY_ERROR, 'querying execute failed.'],
    [ErrorCode.INSERT_ERROR, 'inserting execute failed.'],
    [ErrorCode.UPDATE_ERROR, 'updating execute failed.'],
    [ErrorCode.DELETE_ERROR, 'deleting execute failed.'],
    [ErrorCode.TRUNCATE_ERROR, 'truncating execute failed.'],
    [ErrorCode.UPSERT_ERROR, 'upsert failed.'],
    [ErrorCode.BATCH_UPSERT_ERROR, 'batch upsert failed.'],
    [ErrorCode.BATCH_DELETE_ERROR, 'batch delete failed.'],
    [ErrorCode.RECORD_QUERY_ERROR, 'querying by row failed.'],
    [ErrorCode.RECORD_UPSERT_ERROR, 'upserting by row failed.'],
    [ErrorCode.RECORD_DELETE_ERROR, 'deleting by row failed.'],
    [ErrorCode.RECORD_TRUNCATE_ERROR, 'extracting data from result set failed.'],
    [ErrorCode.RESULT_SET_EXTRACT_ERROR, 'extracting data from result set failed.'],
    [ErrorCode.VALUE_EXTRACT_ERROR, 'extracting data failed.'],
    [ErrorCode.OBJECT_VERSION_GET_ERROR, 'extracting version failed.'],
    [ErrorCode.EXPECTED_VALUE_NOT_FOUND, 'expected value does not exist.'],
    [ErrorCode.DB_CONN_LIMIT_ALTER_ERROR, 'modifying the database connection limit failed.'],
    [ErrorCode.UNSUPPORTED_ERROR, 'unsupported.'],
    [ErrorCode.SCHEMA_QUERY_ERROR, 'querying object type failed.'],
    [ErrorCode.SCHEMA_CONVERT_ERROR, 'object type conversion failed.'],
    [ErrorCode.INSTANCE_ID_GET_ERROR, 'instance id getting error.'],
    [ErrorCode.PRODUCT_MAPPING_NOT_FOUND, 'no valid product mapping info.'],
    [ErrorCode.CLUSTER_NO_FREE, 'no free cluster.'],
    [ErrorCode.GROUP_NOT_EMPTY, 'group is not empty.'],
    [ErrorCode.NODE_GROUP_NO_FREE, 'no free node group.'],
    [ErrorCode.NODE_GROUP_NOT_ALLOCATED, 'node group has not been allocated.'],
    [ErrorCode.INDEX_FIELD_VALUE_LENGTH_EXCEED, 'length of index field exceeds the limit.'],
    [ErrorCode.PRODUCT_INFO_QUERY_ERROR, 'querying product info failed.'],
    [ErrorCode.GENERATE_PRODUCT_SEQUENCE_ERROR, 'generate product sequence failed.'],
    [ErrorCode.VIOLATES_UNIQUE_CONSTRAINT, 'violates unique constraint.']
  ]);
  protected exceptionCode: ErrorCode = ErrorCode.OK;
  protected msg = '';

  constructor(exceptionCode: number) {
    this.check(exceptionCode);
  }

  public getCode() {
    return this.exceptionCode;
  }

  private check(exceptionCode: number) {
    if (BasicException.ErrorMessageMapper.has(exceptionCode)) {
      this.exceptionCode = exceptionCode;
      this.msg = BasicException.ErrorMessageMapper.get(exceptionCode) || '';
    } else {
      this.exceptionCode = ErrorCode.INTERNAL_ERROR;
      this.msg = '';
      Logger.warn(TAG, `Unknown exception code ${exceptionCode}.`);
    }
  }

  public getMsg() {
    return this.msg;
  }

  public toString() {
    return `exceptionCode:${this.exceptionCode},msg:${this.msg}`;
  }
}

export class ExceptionUtil {
  /**
   * Build error message by specific ErrorCode or error info.
   * @param code error code.
   */
  static build(code: number | string): any {
    if (typeof code === 'string') {
      return { message: code };
    } else {
      return this.parseException(new BasicException(code as ErrorCode));
    }
  }

  /**
   * Convert BasicException to DatabaseException.
   * @param basicException specific exception.
   */
  private static parseException(basicException: BasicException): DatabaseException {
    return new DatabaseException(basicException.getMsg(), basicException.getCode());
  }
}
