'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('submission_status', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    }
    status: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'submission_status',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};
