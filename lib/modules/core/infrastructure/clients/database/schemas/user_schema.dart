import 'package:tostore/tostore.dart';

import 'package:trocado/modules/core/domain/constant/database_constant.dart';

final userSchema = TableSchema(
  name: DatabaseConstant.userTableName.name,
  primaryKeyConfig: PrimaryKeyConfig(
    name: 'id',
    type: PrimaryKeyType.timestampBased,
  ),
  fields: [
    FieldSchema(
      name: 'name',
      unique: true,
      maxLength: 32,
      nullable: false,
      type: DataType.text,
      comment: 'User nickname',
    ),
    FieldSchema(
      name: 'email',
      unique: true,
      maxLength: 128,
      nullable: false,
      type: DataType.text,
      comment: 'User e-mail',
    ),
    FieldSchema(
      name: 'photo',
      unique: false,
      maxLength: 254,
      nullable: false,
      type: DataType.text,
      comment: 'Path user photo',
    ),
  ],
);
