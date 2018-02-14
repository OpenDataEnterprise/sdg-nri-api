'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('submission_status', {
    status: {
      type: DataTypes.TEXT,
      primaryKey: true,
    },
  }, {
    tableName: 'submission_status',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};