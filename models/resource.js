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
      },
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
    date_published: {
      type: DataTypes.DATE,
    },
    image_url: {
      type: DataTypes.TEXT,
    },
    description: {
      type: DataTypes.TEXT,
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
    },
    publish: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  }, {
    tableName: 'resource',
    underscored: true,
    timestamps: true,
    schema: process.env.DATABASE_SCHEMA,
    indexes: [
      {
        fields: ['tsv'],
        using: 'gin',
      },
    ],
  });

  Model.associate = (models) => {
    Model.belongsTo(models.country, {
      foreignKey: 'country_id',
    });
    Model.belongsToMany(models.content_type, {
      through: {
        model: 'resource_content_types',
        unique: true,
      },
      foreignKey: 'resource_id',
      otherKey: 'content_type_id',
      constraints: true,
      cascade: true,
    });
    Model.belongsToMany(models.language, {
      through: {
        model: 'resource_languages',
        unique: true,
      },
      foreignKey: 'resource_id',
      otherKey: 'language_id',
      constraints: true,
      cascade: true,
    });
    Model.belongsToMany(models.topic, {
      through: {
        model: 'topic_resources',
        unique: true,
      },
      foreignKey: 'resource_id',
      otherKey: 'topic_id',
      constraints: true,
      cascade: true,
    });
  };

  return Model;
};
