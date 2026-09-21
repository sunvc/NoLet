/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

// keep words lowercase
const SYSTEM_TABLE_INFOHELPER = 'objecttypeinfohelper';
const SYSTEM_TABLE_UPGRADEINFO = 't_data_upgrade_info';
const SYSTEM_TABLE_METADATA = 'naturalbase_metadata';

const SYSTEM_PROPERTY_ROWID = 'rowid';
const SYSTEM_PROPERTY_VERSION = 'naturalbase_version';
const SYSTEM_PROPERTY_SYNCSTATUS = 'naturalbase_syncstatus';
const SYSTEM_PROPERTY_DELETEDSTATUS = 'naturalbase_deleted';
const SYSTEM_PROPERTY_SYNCOPTYPE = 'naturalbase_operationtype';
const SYSTEM_PROPERTY_ACCESSTIME = 'naturalbase_accesstime';
const SYSTEM_PROPERTY_OPERATIONTIME = 'naturalbase_operationtime';
const SYSTEM_PROPERTY_CREATOR = 'naturalbase_creator';
const SYSTEM_PROPERTY_LASTMODIFIER = 'naturalbase_lastmodifier';

export const SYSTEM_PROPERTY_SET: Set<string> = new Set([
  SYSTEM_PROPERTY_ROWID,
  SYSTEM_PROPERTY_VERSION,
  SYSTEM_PROPERTY_SYNCSTATUS,
  SYSTEM_PROPERTY_DELETEDSTATUS,
  SYSTEM_PROPERTY_SYNCOPTYPE,
  SYSTEM_PROPERTY_ACCESSTIME,
  SYSTEM_PROPERTY_OPERATIONTIME,
  SYSTEM_PROPERTY_CREATOR,
  SYSTEM_PROPERTY_LASTMODIFIER
]);

export const SYSTEM_TABLE_SET: Set<string> = new Set([
  SYSTEM_TABLE_INFOHELPER,
  SYSTEM_TABLE_UPGRADEINFO,
  SYSTEM_TABLE_METADATA
]);
