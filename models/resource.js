'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource', {
    uuid: {
      type: DataTypes.UUID,
      defaultValue: sequelize.literal('uuid_generate_v1mc()'),
      primaryKey: true,
    },
    country_id: {
      type: DataTypes.CHAR(3),
      references: {
        model: sequelize.models.country,
        key: 'iso_alpha3',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE,
      }
    },
    resource_type_id: {
      type: DataTypes.UUID,
      references: {
        model: sequelize.models.resource_type,
        key: 'id',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE,
      }
    },
    title: {
      type: DataTypes.STRING,
    },
    organization: {
      type: DataTypes.STRING,
    },
    url: {
      type: DataTypes.STRING,
    },
    date_published: {
      type: DataTypes.DATE,
    },
    image_url: {
      type: DataTypes.STRING,
    },
    description: {
      type: DataTypes.STRING,
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.STRING),
    },
    publish: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    }
  }, {
    tableName: 'resource',
    underscored: true,
    timestamps: true,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.country, {
      foreignKey: 'country_id',
    });
    Model.belongsTo(models.resource_type, {
      foreignKey: 'resource_type_id',
    });
    Model.belongsToMany(models.language, {
      through: {
        model: 'resource_languages',
        unique: false,
      },
      foreignKey: 'resource_id',
      otherKey: 'language_id',
      constraints: true,
      cascade: true,
    });
    Model.belongsToMany(models.topic, {
      through: {
        model: 'topic_resources',
        unique: false,
      },
      foreignKey: 'resource_id',
      otherKey: 'topic_id',
      constraints: true,
    });
  };

  return Model;
};

