'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_languages', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    resource_id: {
      type: DataTypes.INTEGER,
      references: {
        model: sequelize.models.reference,
        key: 'uuid',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE
      }
    },
    language_id: {
      type: DataTypes.STRING,
      references: {
        model: sequelize.models.language,
        key: 'ietf_tag',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE
      }
    },
  }, {
    tableName: 'resource_languages',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.language, {
      foreignKey: 'language_id',
    });
  };

  return Model;
};
