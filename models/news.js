'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('news', {
    uuid: {
      type: DataTypes.UUID,
      defaultValue: sequelize.literal('uuid_generate_v1mc()'),
      primaryKey: true,
    },
    title: {
      type: DataTypes.TEXT,
    },
    organization: {
      type: DataTypes.TEXT,
    },
    url: {
      type: DataTypes.TEXT,
    },
    description: {
      type: DataTypes.TEXT,
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
    },
  }, {
    tableName: 'news',
    underscored: true,
    timestamps: true,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};