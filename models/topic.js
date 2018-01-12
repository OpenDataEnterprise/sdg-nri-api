'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('topic', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    tag: {
      type: DataTypes.STRING,
    },
    path: {
      type: DataTypes.STRING,
    },
    label: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'topic',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

