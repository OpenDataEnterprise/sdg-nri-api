'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('language', {
    ietf_tag: {
      type: DataTypes.STRING,
      primaryKey: true 
    },
    name: {
      type: DataTypes.STRING,
    },
    label: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'language',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsToMany(models.language, {
      through: 'resource_languages'
    });
  };

  return Model;
};

