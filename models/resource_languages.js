'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_languages', {
    resource_id: {
      type: DataTypes.INTEGER,
    },
    language_ietf_tag: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'resource_languages',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

