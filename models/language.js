'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('language', {
    ietf_tag: {
      type: DataTypes.TEXT,
      primaryKey: true,
    },
    name: {
      type: DataTypes.TEXT,
    },
    label: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'language',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsToMany(models.resource, {
      through: 'resource_languages',
      foreignKey: 'language_id',
    });
  };

  return Model;
};