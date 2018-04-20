-- Provide UUID generation functions.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Provide LTREE data type support.
CREATE EXTENSION IF NOT EXISTS "ltree";

CREATE SCHEMA IF NOT EXISTS sdg;

CREATE TABLE IF NOT EXISTS sdg.topic (
    id SERIAL PRIMARY KEY,
    topic TEXT UNIQUE NOT NULL,
    path LTREE UNIQUE NOT NULL,
    label TEXT NOT NULL,
    ordering LTREE UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.region (
    m49 CHARACTER(3) PRIMARY KEY,
    path LTREE UNIQUE NOT NULL,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.country (
    iso_alpha3 CHARACTER(3) PRIMARY KEY,
    region_id CHARACTER(3) REFERENCES sdg.region (m49) ON UPDATE CASCADE,
    income_group TEXT CHECK (income_group IN ('High', 'Upper-middle', 'Lower-middle', 'Low')),
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.language (
    ietf_tag TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    label TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.content_type (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.tag (
    uuid UUID PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.resource (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
    content_type_id INTEGER REFERENCES sdg.content_type (id) ON UPDATE CASCADE,
    country_id CHARACTER(3) REFERENCES sdg.country (iso_alpha3) ON UPDATE CASCADE,
    title TEXT NOT NULL,
    organization TEXT,
    url TEXT NOT NULL,
    date_published TIMESTAMPTZ,
    image_url TEXT,
    description TEXT,
    tags TEXT[],
    publish BOOLEAN DEFAULT FALSE,
    tsv TSVECTOR,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sdg.submission_status (
    id SERIAL PRIMARY KEY,
    status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sdg.submission (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    status_id INTEGER REFERENCES sdg.submission_status (id),
    submitter_country_id CHARACTER(3) REFERENCES sdg.country (iso_alpha3) ON UPDATE CASCADE,
    submitter_name TEXT,
    submitter_organization TEXT,
    submitter_title TEXT,
    submitter_email TEXT,
    submitter_city TEXT,
    tags TEXT[],
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sdg.news (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
    title TEXT NOT NULL,
    organization TEXT,
    url TEXT,
    description TEXT,
    tags TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sdg.event (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
    title TEXT NOT NULL,
    url TEXT,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    locations TEXT[],
    tags TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

/**
 * Create associative tables.
 */
CREATE TABLE IF NOT EXISTS sdg.resource_topics (
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    topic_id INTEGER REFERENCES sdg.topic (id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (topic_id, resource_id)
);

CREATE TABLE IF NOT EXISTS sdg.resource_languages (
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    language_id TEXT REFERENCES sdg.language (ietf_tag) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (resource_id, language_id)
);

CREATE TABLE IF NOT EXISTS sdg.resource_content_types (
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    content_type_id INTEGER REFERENCES sdg.content_type (id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (resource_id, content_type_id)
);

CREATE TABLE IF NOT EXISTS sdg.resource_tags (
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    tag_id UUID REFERENCES sdg.tag (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (resource_id, tag_id)
);

-- Create search index on resource text search field.
CREATE INDEX resource_tsv_idx ON sdg.resource USING gin(tsv);

-- Create search index update function.
CREATE OR REPLACE FUNCTION resource_tsv_update_trigger() RETURNS trigger AS $$
BEGIN
    NEW.tsv :=
        setweight(to_tsvector('english', COALESCE(NEW.title,'')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.organization,'')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.description,'')), 'C');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Create text search function.
CREATE OR REPLACE FUNCTION tsmatch(a tsvector, b tsquery) RETURNS boolean AS $$
BEGIN
    RETURN a @@ b;
END;
$$ LANGUAGE plpgsql;

-- Trigger search index (re)generation on resource row inserts or updates.
CREATE TRIGGER resource_tsv_update
    BEFORE INSERT OR UPDATE ON sdg.resource
    FOR EACH ROW EXECUTE PROCEDURE resource_tsv_update_trigger();

-- Load initial topics.
INSERT INTO sdg.topic (topic, path, label, ordering) VALUES
('sdg', 'sdg', 'Why SDG reporting?', '1'),
('intro', 'sdg.intro', 'What are the SDGs and the Data Revolution?', '1.1'),
('reporting', 'sdg.reporting', 'What is SDG reporting?', '1.2'),
('indicators', 'sdg.indicators', 'The global SDG indicators', '1.3'),
('approaches', 'approaches', 'Current approaches to SDG reporting', '2'),
('priorities', 'priorities', 'Assessing reporting priorities and needs', '3'),
('policy', 'priorities.policy', 'Policy considerations', '3.1'),
('engagement', 'priorities.engagement', 'Stakeholder engagement', '3.2'),
('financing', 'priorities.financing', 'Financing and sustainability', '3.3'),
('capacity', 'priorities.capacity', 'Capacity-building', '3.4'),
('data', 'data', 'Data and technical', '4'),
('assessment', 'data.assessment', 'Identifying data sources and gaps', '4.1'),
('standards', 'data.standards', 'Open data, metadata, and standards', '4.2'),
('technology', 'data.technology', 'Types of technology', '4.3'),
('features', 'data.features', 'Features and functionality', '4.4'),
('opensource', 'opensource', 'Open-source solutions', '5'),
('platforms', 'opensource.platforms', 'Open-source reporting platforms', '5.1'),
('versioncontrol', 'opensource.versioncontrol', 'Introduction to version control', '5.2'),
('forking', 'opensource.forking', 'Forking an open-source platform', '5.3'),
('addingdata', 'opensource.addingdata', 'Adding data to a platform', '5.4'),
('customization', 'opensource.customization', 'Customization and additional features', '5.5'),
('countries', 'countries', 'Country Experiences', '6');

-- Load initial languages.
INSERT INTO sdg.language (ietf_tag, name, label) VALUES
('en', 'English', 'English'),
('fr', 'French', 'français'),
('es', 'Spanish', 'Español'),
('ru', 'Russian', 'Русский'),
('zh', 'Chinese', '中文'),
('ar', 'Arabic', 'العربية'),
('de', 'German', 'Deutsch'),
('ja', 'Japanese', '日本語'),
('ko', 'Korean', '한국어'),
('da', 'Danish', 'dansk'),
('cz', 'Czech', 'čeština'),
('et', 'Estonian', 'eesti'),
('fi', 'Finnish', 'suomi'),
('el', 'Greek', 'ελληνικά'),
('he', 'Hebrew', 'עברית'),
('hu', 'Hungarian', 'magyar'),
('is', 'Icelandic', 'Íslenska'),
('it', 'Italian', 'Italiano'),
('lv', 'Latvian', 'Latviešu Valoda'),
('no', 'Norwegian', 'Norsk'),
('pl', 'Polish', 'Polszczyzna'),
('pt', 'Portuguese', 'Português'),
('sl', 'Slovenian', 'Slovenščina'),
('sv', 'Swedish', 'Svenska'),
('tr', 'Turkish', 'Türkçe');

-- Load region scheme.
INSERT INTO sdg.region (m49, path, name) VALUES
('001', '001', 'World'),
('002', '001.002', 'Africa'),
('015', '001.015', 'Northern Africa'),
('202', '001.202', 'Sub-Saharan Africa'),
('014', '001.202.014', 'Eastern Africa'),
('017', '001.202.017', 'Middle Africa'),
('018', '001.202.018', 'Southern Africa'),
('011', '001.202.011', 'Western Africa'),
('019', '001.019', 'The Americas'),
('419', '001.019.419', 'Latin America and the Caribbean'),
('029', '001.019.419.029', 'Caribbean'),
('013', '001.019.419.013', 'Central America'),
('005', '001.019.419.005', 'South America'),
('021', '001.019.021', 'Northern America'),
('142', '001.142', 'Asia'),
('143', '001.142.143', 'Central Asia'),
('030', '001.142.030', 'Eastern Asia'),
('035', '001.142.035', 'South-eastern Asia'),
('034', '001.142.034', 'Southern Asia'),
('145', '001.142.145', 'Western Asia'),
('150', '001.150', 'Europe'),
('151', '001.150.151', 'Eastern Europe'),
('154', '001.150.154', 'Northern Europe'),
('039', '001.150.039', 'Southern Europe'),
('155', '001.150.155', 'Western Europe'),
('009', '001.009', 'Oceania'),
('053', '001.009.053', 'Australia and New Zealand'),
('054', '001.009.054', 'Melanesia'),
('057', '001.009.057', 'Micronesia'),
('061', '001.009.061', 'Polynesia');

-- Load initial list of countries (UN member countries).
INSERT INTO sdg.country (iso_alpha3, region_id, name) VALUES
('AFG', '034', 'Afghanistan'),
('ALB', '039', 'Albania'),
('DZA', '015', 'Algeria'),
('AND', '039', 'Andorra'),
('AGO', '017', 'Angola'),
('ATG', '029', 'Antigua and Barbuda'),
('ARG', '005', 'Argentina'),
('ARM', '145', 'Armenia'),
('AUS', '053', 'Australia'),
('AUT', '155', 'Austria'),
('AZE', '145', 'Azerbaijan'),
('BHS', '029', 'Bahamas'),
('BHR', '145', 'Bahrain'),
('BGD', '034', 'Bangladesh'),
('BRB', '029', 'Barbados'),
('BLR', '151', 'Belarus'),
('BEL', '155', 'Belgium'),
('BLZ', '005', 'Belize'),
('BEN', '011', 'Benin'),
('BTN', '034', 'Bhutan'),
('BOL', '005', 'Bolivia'),
('BIH', '039', 'Bosnia and Herzegovina'),
('BWA', '018', 'Botswana'),
('BRA', '005', 'Brazil'),
('BRN', '035', 'Brunei Darussalam'),
('BGR', '151', 'Bulgaria'),
('BFA', '011', 'Burkina Faso'),
('BDI', '014', 'Burundi'),
('CPV', '011', 'Cabo Verde'),
('KHM', '035', 'Cambodia'),
('CMR', '017', 'Cameroon'),
('CAN', '021', 'Canada'),
('CAF', '017', 'Central African Republic'),
('TCD', '017', 'Chad'),
('CHL', '005', 'Chile'),
('CHN', '030', 'China'),
('COL', '005', 'Colombia'),
('COM', '014', 'Comoros'),
('COG', '017', 'Congo'),
('CRI', '029', 'Costa Rica'),
('CIV', '011', 'Côte d''Ivoire'),
('HRV', '039', 'Croatia'),
('CUB', '029', 'Cuba'),
('CYP', '145', 'Cyprus'),
('CZE', '151', 'Czech Republic'),
('DNK', '155', 'Denmark'),
('DJI', '014', 'Djibouti'),
('DMA', '029', 'Dominica'),
('DOM', '029', 'Dominican Republic'),
('COD', '017', 'DR Congo'),
('ECU', '005', 'Ecuador'),
('EGY', '015', 'Egypt'),
('SLV', '013', 'El Salvador'),
('GNQ', '017', 'Equatorial Guinea'),
('ERI', '014', 'Eritrea'),
('EST', '154', 'Estonia'),
('ETH', '014', 'Ethiopia'),
('FJI', '054', 'Fiji'),
('FIN', '154', 'Finland'),
('FRA', '155', 'France'),
('GAB', '017', 'Gabon'),
('GMB', '011', 'Gambia'),
('GEO', '145', 'Georgia'),
('DEU', '155', 'Germany'),
('GHA', '011', 'Ghana'),
('GRC', '039', 'Greece'),
('GRD', '029', 'Grenada'),
('GTM', '013', 'Guatemala'),
('GIN', '011', 'Guinea'),
('GNB', '011', 'Guinea-Bissau'),
('GUY', '005', 'Guyana'),
('HTI', '029', 'Haiti'),
('VAT', '039', 'Holy See'),
('HND', '013', 'Honduras'),
('HUN', '151', 'Hungary'),
('ISL', '154', 'Iceland'),
('IND', '034', 'India'),
('IDN', '035', 'Indonesia'),
('IRN', '145', 'Iran'),
('IRQ', '145', 'Iraq'),
('IRL', '155', 'Ireland'),
('ISR', '145', 'Israel'),
('ITA', '039', 'Italy'),
('JAM', '029', 'Jamaica'),
('JPN', '030', 'Japan'),
('JOR', '145', 'Jordan'),
('KAZ', '143', 'Kazakhstan'),
('KEN', '014', 'Kenya'),
('KIR', '057', 'Kiribati'),
('KWT', '145', 'Kuwait'),
('KGZ', '143', 'Kyrgyzstan'),
('LAO', '035', 'Laos'),
('LVA', '154', 'Latvia'),
('LBN', '145', 'Lebanon'),
('LSO', '018', 'Lesotho'),
('LBR', '011', 'Liberia'),
('LBY', '015', 'Libya'),
('LIE', '155', 'Liechtenstein'),
('LTU', '154', 'Lithuania'),
('LUX', '155', 'Luxembourg'),
('MKD', '039', 'Macedonia'),
('MDG', '014', 'Madagascar'),
('MWI', '014', 'Malawi'),
('MYS', '035', 'Malaysia'),
('MDV', '034', 'Maldives'),
('MLI', '011', 'Mali'),
('MLT', '039', 'Malta'),
('MHL', '057', 'Marshall Islands'),
('MRT', '011', 'Mauritania'),
('MUS', '014', 'Mauritius'),
('MEX', '013', 'Mexico'),
('FSM', '057', 'Micronesia'),
('MDA', '151', 'Moldova'),
('MCO', '155', 'Monaco'),
('MNG', '030', 'Mongolia'),
('MNE', '039', 'Montenegro'),
('MAR', '015', 'Morocco'),
('MOZ', '014', 'Mozambique'),
('MMR', '035', 'Myanmar'),
('NAM', '018', 'Namibia'),
('NRU', '057', 'Nauru'),
('NPL', '034', 'Nepal'),
('NLD', '155', 'Netherlands'),
('NZL', '053', 'New Zealand'),
('NIC', '013', 'Nicaragua'),
('NER', '011', 'Niger'),
('NGA', '011', 'Nigeria'),
('PRK', '030', 'North Korea'),
('NOR', '154', 'Norway'),
('OMN', '145', 'Oman'),
('PAK', '034', 'Pakistan'),
('PLW', '057', 'Palau'),
('PAN', '013', 'Panama'),
('PNG', '054', 'Papua New Guinea'),
('PRY', '005', 'Paraguay'),
('PER', '005', 'Peru'),
('PHL', '035', 'Philippines'),
('POL', '151', 'Poland'),
('PRT', '039', 'Portugal'),
('QAT', '145', 'Qatar'),
('ROU', '151', 'Romania'),
('RUS', '151', 'Russian Federation'),
('RWA', '014', 'Rwanda'),
('KNA', '029', 'Saint Kitts and Nevis'),
('LCA', '029', 'Saint Lucia'),
('VCT', '029', 'Saint Vincent and the Grenadines'),
('WSM', '061', 'Samoa'),
('SMR', '039', 'San Marino'),
('STP', '017', 'Sao Tome and Principe'),
('SAU', '145', 'Saudi Arabia'),
('SEN', '011', 'Senegal'),
('SRB', '039', 'Serbia'),
('SYC', '014', 'Seychelles'),
('SLE', '011', 'Sierra Leone'),
('SGP', '035', 'Singapore'),
('SVK', '151', 'Slovakia'),
('SVN', '039', 'Slovenia'),
('SLB', '054', 'Solomon Islands'),
('SOM', '014', 'Somalia'),
('ZAF', '018', 'South Africa'),
('ROK', '030', 'South Korea'),
('SSD', '014', 'South Sudan'),
('ESP', '039', 'Spain'),
('LKA', '034', 'Sri Lanka'),
('SDN', '015', 'Sudan'),
('SUR', '005', 'Suriname'),
('SWZ', '018', 'Swaziland'),
('SWE', '154', 'Sweden'),
('CHE', '155', 'Switzerland'),
('SYR', '145', 'Syria'),
('TJK', '143', 'Tajikistan'),
('TZA', '014', 'Tanzania'),
('THA', '035', 'Thailand'),
('TLS', '035', 'Timor-Leste'),
('TGO', '011', 'Togo'),
('TON', '061', 'Tonga'),
('TTO', '029', 'Trinidad and Tobago'),
('TUN', '015', 'Tunisia'),
('TUR', '145', 'Turkey'),
('TKM', '143', 'Turkmenistan'),
('TUV', '061', 'Tuvalu'),
('UGA', '014', 'Uganda'),
('UKR', '151', 'Ukraine'),
('ARE', '145', 'United Arab Emirates'),
('GBR', '155', 'United Kingdom'),
('USA', '021', 'United States'),
('URY', '005', 'Uruguay'),
('UZB', '143', 'Uzbekistan'),
('VUT', '054', 'Vanuatu'),
('VEN', '005', 'Venezuela'),
('VNM', '035', 'Vietnam'),
('YEM', '145', 'Yemen'),
('ZMB', '014', 'Zambia'),
('ZWE', '014', 'Zimbabwe');

-- Load initial list of content types.
INSERT INTO sdg.content_type (id, name) VALUES
(1, 'Report'),
(2, 'Article'),
(3, 'Guide'),
(4, 'Assessment'),
(5, 'Webinar'),
(6, 'Presentation'),
(7, 'Website'),
(8, 'Conference Proceedings'),
(9, 'Repository'),
(10, 'Video');

-- Load initial list of submission states.
INSERT INTO sdg.submission_status (id, status) VALUES
(1, 'Unreviewed'),
(2, 'Under review'),
(3, 'Accepted');

/**
 * Load initial resources.
 */
WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES
  (
    'Center for Open Data Enterprise',
    'SDG reporting links, by country',
    'https://docs.google.com/spreadsheets/d/1kaODycDA6QH5OTbyD1tUws1xtxNfGltROco5xebXKrc/edit#gid=630534804',
    'A working list of links to country SDG reporting websites, data assessments and Voluntary National Reports',
    NULL,
    '{"Country experience"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'approaches')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UN Development Group',
    'SDG Country Reporting Guidelines - Presentation',
    'https://unstats.un.org/sdgs/files/meetings/sdg-inter-agency-meeting-2017/8.UNDG%20WG%20on%20SD-SDG%20Country%20Reporting%20Guidelines.pdf',
    'A summary of UNDP''s "Guidelines to Support Country Reporting" paper.',
    NULL,
    '{"Engagement"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'engagement')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE) Steering Group on SDG Statistics',
    'Self-assessment template for countries on availability of global SDG indicators',
    'http://www1.unece.org/stat/platform/download/attachments/127666441/Self-assessment%20template%20on%20availability%20of%20SDG%20indicators.xlsx?version=3&modificationDate=1484038447257&api=v2',
    'A template for governments to assess their data availability for the global SDG indicators.',
    NULL,
    '2017-03-01 00:00:00',
    '{"Data", "Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'indicators')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Statistical Data and Metadata eXchange (SDMX)',
    'Learning about Statistical Data and Metadata eXchange (SDMX) basics',
    'https://sdmx.org/?page_id=2555/',
    'An introduction to SDMX, an international initiative that aims at standardizing and modernizing the mechanisms and processes for the exchange of statistical data and metadata among international organizations and countries.',
    NULL,
    '{"Standards"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Statistics Division',
    'Cape Town Global Action Plan for Sustainable Development Data (CTGAP)',
    'https://unstats.un.org/sdgs/hlg/Cape-Town-Global-Action-Plan/',
    'Prepared by the High-level Group for Partnership, Coordination and Capacity-Building for Statistics for the 2030 Agenda for Sustainable Development, the Plan proposes six strategic areas, each associated with several objectives and implementation actions.',
    NULL,
    '2017-01-01 00:00:00',
    '{"Financing", "Capacity", "Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'intro')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'financing')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Arabic')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Chinese')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'French')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Russian')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Spanish')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published) VALUES    
  (
    'UN Independent Expert Advisory Group on a Data Revolution for Sustainable Development (IAEG-SDGs)',
    'A World That Counts: Mobilising the Data Revolution for Sustainable Development',
    'http://www.undatarevolution.org/wp-content/uploads/2014/11/A-World-That-Counts.pdf',
    'An overview of the data revolution for sustainable development, recomendations, and a call to action to the global community.',
    NULL,
    '2014-11-01 00:00:00'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'intro')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Sustainable Development Solutions Network (SDSN)',
    'SDG Index and Dashboards Report',
    'http://sdgindex.org/#full-report',
    'An index and report card for each country on its performance on the 2030 Agenda and the SDGs.',
    NULL,
    '{"Country experience"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Development Group',
    'Guidelines to Support Country Reporting on the Sustainable Development Goals',
    'https://undg.org/wp-content/uploads/2017/03/Guidelines-to-Support-Country-Reporting-on-SDGs-1.pdf',
    'UN guidelines for creating national reports on the SDGs, including: SDG review and follow-up process; elements for inclusive country-led reporting; SDG indicators, data, and progressive reviews; and stakeholder engagement.',
    NULL,
    '2017-04-01 00:00:00',
    '{"Indicators", "Engagement"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'PARIS21',
    'Making Data Portals work for SDGs: A view on deployment, design and technology',
    'https://www.paris21.org/sites/default/files/Paper_on_Data_Portals%20wcover_WEB.pdf',
    'An analysis of the sustainability and current use of data portals, and recommendations on the design and technology considerations for countries and their National Statistical Offices (NSOs).',
    NULL,
    '2016-04-01 00:00:00',
    '{"Technology", "Sustainability"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'PARIS21',
    'Advanced Data Planning Tool (ADAPT)',
    'http://adapt.paris21.org/auth/login',
    'A consultative tool that brings development stakeholders together to define measurement standards within indicator frameworks in order to monitor development.',
    NULL,
    '{"Data", "Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Center for Open Data Enterprise',
    'U.S. SDG Data Revolution Roadmap - Roundtable Report',
    'http://reports.opendataenterprise.org/us-sdg-report.pdf',
    'A report from a Roundtable to develop a Sustainable Development Goals Data Roadmap for the US Government.',
    'USA',
    '2017-01-01 00:00:00',
    '{"Country experience", "United States"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'United Nations',
    'United Nations Sustainable Development Goals',
    'http://www.un.org/sustainabledevelopment/sustainable-development-goals/',
    'A UN website including information on the SDGs, their targets and indicators, as well as facts and links providing information on the current status of the SDGs.',
    NULL,
    '{"Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'intro')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Arabic')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Chinese')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'French')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Russian')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Spanish')
);




WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UN Independent Expert Advisory Group on a Data Revolution for Sustainable Development (IAEG-SDGs)',
    'IAEG-SDGs - Tier Classification for Global SDG Indicators',
    'https://unstats.un.org/sdgs/iaeg-sdgs/tier-classification/',
    'Guidelines on the three different tiers of indicators on the basis of their level of methodological development and the availability of data at the global level.',
    NULL,
    '{"Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'indicators')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Arabic')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Chinese')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'French')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Russian')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Spanish')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UK Office for National Statistics',
    'How should the UK report progress towards the Sustainable Development Goals? A summary of responses from non-governmental organisations',
    'https://www.ons.gov.uk/file?uri=/aboutus/whatwedo/programmesandprojects/sustainabledevelopmentgoals/howshouldtheukreportprogresstowardsthesustainabledevelopmentgoals.pdf',
    'A summary of responses from a consultation with non-government actors on how the UK should report progress on the SDGs.',
    'GBR',
    '2016-08-01 00:00:00',
    '{"Engagement", "Country experience", "United Kingdom"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'engagement')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UK Office for National Statistics',
    'Sustainable Development Goals: progress and possibilities',
    'https://www.ons.gov.uk/economy/environmentalaccounts/articles/sustainabledevelopmentgoalstakingstockprogressandpossibilities/november2017',
    'An initial assessment of SDG measuring and reporting efforts in the UK.',
    'GBR',
    '2017-11-01 00:00:00',
    '{"Country experience", "United Kingdom"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE), Conference of European Statisticians'' Steering Group on Statistics for SDGs',
    'Road Map on Statistics for Sustainable Development Goals, First Edition',
    'https://statswiki.unece.org/display/SFSDG/Statistics+for+SDGs+Home?preview=/127666441/141230208/CES%20Road%20Map%20for%20SDGs_First%20Edition_final.pdf',
    'This document lays out the activities associated with producing statistics on the SDGs and provides recommendations and actions to NSOs for more efficient implementation of reporting systems.',
    NULL,
    '2016-06-01 00:00:00',
    '{"Policy", "Engagement", "Data", "Capacity", "Country experience"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'engagement')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    NULL,
    'UK national reporting platform repository',
    'https://github.com/datasciencecampus/sdg-indicators',
    'An open-source SDG NRP based on Jekyll and leveraging Github for static hosting, user-management, and data management (with Prose.io). Features include disaggregation, automated tests, and accessibility compliance.',
    'GBR',
    '{"Open source", "Technology", "National Reporting Platform", "Tidy data format", "Disaggregation", "Accessibility", "Automated testing", "Static hosting", "Search", "Github", "Jekyll", "Ruby", "Python", "JavaScript", "United Kingdom"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'platforms')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Repository')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id) VALUES    
  (
    NULL,
    'US national reporting platform repository',
    'https://github.com/GSA/sdg-indicators',
    'An open-source SDG NRP based on Jekyll and leveraging Github for static hosting, user-management, and data management (with Prose.io). Features include multilingual capabilities.',
    'USA'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'platforms')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Repository')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    NULL,
    'Mexico national reporting platform repository',
    'https://github.com/danvaros/visualizadorObjetivosV2',
    'An open-source web-based front-end for sharing and visualizing data from the ods.org.mx API. Features include: subnational mapping, search, calendar.',
    'MEX',
    '{"Open source", "Technology", "National Reporting Platform", "Subnational", "Search", "PHP", "Javascript", "Mexico"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'platforms')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Repository')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Spanish')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Center for Policy Dialogue',
    'Implementing Agenda 2030: Unpacking the Data Revolution at Country Level',
    'http://www.post2015datatest.com/wp-content/uploads/2016/07/Implementing-Agenda-2030-Unpacking-the-Data-Revolution-at-Country-Level.pdf',
    'Opportunities and challenges for effectively applying and measuring a country-relevant SDG framework, based on country studies from seven low-, middle- and high-income countries.',
    NULL,
    '2016-07-01 00:00:00',
    '{"Policy", "Country experience"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Center for Open Data Enterprise',
    'Strategies for SDG National Reporting: A Review of Current Approaches and Key Considerations for Governmnet Reporting on the UN Sustainable Development Goals.',
    '',
    'An overview of the various approaches to SDG reporting and key policy and technical considerations for national governments.',
    NULL,
    '2018-03-01 00:00:00',
    '{"Policy", "Data", "Technology", "Sustainability", "Country experience", "Financing", "Capacity"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'approaches')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE), Conference of European Statisticians'' Steering Group on Statistics for SDGs',
    'National Mechanisms for Providing Data on SDG indicators',
    'https://statswiki.unece.org/display/SFSDG/Task+Force+on+National+Reporting+Platforms?preview=/128451803/170164504/National%20mechanisms%20for%20providing%20data%20on%20SDGs_note%20from%20UNCES%20SG%20SDG%20TF...pdf',
    'Guidelines to help NSOs in choosing mechanisms for providing data on SDG indicators. Aspects of data flow that are considered include: the role of various actors, the various types of data, and models for national reporting on the global SDG indicators.',
    NULL,
    '2018-01-17 00:00:00',
    '{"Data", "Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'United Nations',
    'Global indicator framework for the Sustainable Development Goals and targets of the 2030 Agenda for Sustainable Development',
    'https://unstats.un.org/sdgs/indicators/indicators-list/',
    'This document lists the SDG targets and indicators.',
    NULL,
    '{"Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'indicators')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE), Conference of European Statisticians'' Steering Group on Statistics for SDGs',
    'Survey on NSOs strategies and plans related to statistics for SDGs - Questionnaire',
    'https://statswiki.unece.org/download/attachments/127666441/CES%20Survey%20on%20statistics%20for%20SDGs.docx?version=1&modificationDate=1485182757591&api=v2',
    'An assessment tool designed to gather information about National Statistical Offices (NSOs) in four areas: SDG indicators at the country level, communication between policy level and other stakeholders in the country, statistical capacities of NSOs, and strategic issues and challenges.',
    NULL,
    '{"Indicators", "Engagement", "Capacity"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Global Partnership for Sustainable Development Data (GPSDD)',
    'Data Roadmaps for Sustainable Development Guidelines',
    'http://www.data4sdgs.org/sites/default/files/2017-09/Data%20Roadmaps%20for%20Sustainable%20Development%20Guidelines%20-%20Data4SDGs%20Toolbox.pdf',
    'Guidelines to help governments advance their own data roadmaps and align them with the global SDGs.',
    NULL,
    '2016-08-12 00:00:00',
    '{"Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'OECD',
    'Development Cooperation Report 2017: Data for Development',
    'http://www.oecd-ilibrary.org/docserver/download/4317041e.pdf?expires=1519316350&id=id&accname=guest&checksum=857EDCA9BD41E8C9F3193FE7DEDAC71C',
    'This report focuses on making data work for development by recognizing the importance of NSOs in the data revolution, gaining donor support in order to increase the statistical capacity of NSOs, and making better use of results data in order to get development finances right.',
    NULL,
    '2017-10-17 00:00:00',
    '{"Financing", "Capacity", "Sustainability"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'financing')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'United Nations',
    'Addis Ababa Action Agenda: Monitoring commitments and actions',
    'http://www.un.org/esa/ffd/wp-content/uploads/2016/03/Report_IATF-2016-full.pdf',
    'This report outlines the commitments and action items from the Addis Ababa Action Agenda and outlines how the Inter-Agency Task Force on Financing and Development will monitor implementation in the future.',
    NULL,
    '2016-01-01 00:00:00',
    '{"Financing", "Sustainability"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'financing')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Global Partnership for Sustainable Development Data (GPSDD)',
    'Data Financing and Mutual Accountability Pact',
    'http://www.data4sdgs.org/resources/data-financing-and-mutual-accountability-pact',
    'An agreement between national governments, local governments, funders, and other relevant parties whereby funders reward subnational governments for progress in producing and publishing better (more timely, open, accurate, complete) data.',
    NULL,
    '{"Financing", "Subnational"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'financing')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Sustainable Development Solutions Network (SDSN)',
    'Data for Development: A Needs Assessment for SDG Monitoring and Statistical Capacity Development',
    'http://unsdsn.org/wp-content/uploads/2015/04/Data-for-Development-Full-Report.pdf',
    'This document informs the discussion at the Financing for Development Conference by demonstrating the scale of need, including total and additional resources required, as well as the key areas for investment.  The document also identifies some ways in which data production and communication can be modernized.',
    NULL,
    '2015-04-17 00:00:00',
    '{"Financing", "Capacity"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'financing')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'capacity')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'International Association for Statistical Education (IASE)',
    'International Statistical Literacy Project',
    'https://iase-web.org/islp/',
    'A project that aims to promote statistical literacy across all demographics all over the world.',
    NULL,
    '{"Capacity"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'capacity')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Statistics Sweden',
    'Statistical follow-up of the 2030 Agenda for Sustainable development',
    'https://www.scb.se/contentassets/cc84f7debf404250a146e1204ea589b0/mi1303_2017a01_br_x41br1701eng.pdf',
    'An analysis of Sweden’s data and results, as they pertain to the SDGs and their targets in 2017.',
    'SWE',
    '2017-01-01 00:00:00',
    '{"Sweden", "Country experience"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'PARIS21',
    'NSDS Guidelines',
    'http://nsdsguidelines.paris21.org/node/717',
    'This document is a frequently updated list of rules and guidelines that outline how to create a coherent national statistics strategy.',
    NULL,
    '2017-04-01 00:00:00',
    '{"Standards", "Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Statistics Division',
    'Fundamental Principles of Official Statistics',
    'https://unstats.un.org/unsd/dnss/gp/FP-New-E.pdf',
    'A set of principles, adopted by the UN in 2014, that outlines the importance of official statistics across international boundaries as well as offers guidelines for international professional and scientific statistical standards.',
    NULL,
    '2014-01-29 00:00:00',
    '{"Policy", "Standards"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'African Development Bank',
    'A New Lane for the Sustainable Development Goals',
    'https://unstats.un.org/sdgs/files/meetings/sdg-seminar-seoul-2017/S1_P2_Louis_Kouakou_and_Momar_Kouta.pdf',
    'This presentation outlines key features of the Africa Information Highway, a regional open data platform that electronically links all 54 African nations. The presentation displays the components, objectives, features, functionalities, and benefits of the platform.',
    NULL,
    '{"Regional platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'approaches')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published) VALUES    
  (
    'United Nations',
    'The Sustainable Development Goals Report',
    'https://unstats.un.org/sdgs/report/2017/',
    'This report reviews progress made towards the 17 Goals in the second year of implementation of the 2030 Agenda for Sustainable Development.',
    NULL,
    '2017-01-01 00:00:00'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Arabic')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Chinese')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'French')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Russian')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Spanish')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UN Statistics Division',
    'Guidelines and Best Practices on Data Flows and Global Data Reporting for the Sustainable Development Goals',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/20171108_Draft%20Guidelines%20and%20Best%20Practices%20for%20Global%20SDG%20Data%20Reporting.pdf',
    'This document establishes principles for global SDG data reporting, and identifies an approach for National and International Statistical Systems to ensure the quality of the official data and official statistics used for global reporting.',
    NULL,
    '{"Data"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);




WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UN Statistics Division',
    'Overview of Standards for Data Disaggregation',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/20170607_updated%20version-overview%20of%20standards%20of%20data%20disaggregation.pdf',
    'A collection of standards already in use for presenting disaggregated data, and a table including ideas on how to proceed with data disaggregation for the SDG indicators.',
    NULL,
    '{"Data", "Standards", "Disaggregation"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Guide')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UN Statistics Division',
    'Summary Table of SDG Indicators',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/Summary%20Table_Global%20Indicator%20Framework_08.11.2017.pdf',
    'A list of all SDG indicators and their associated tier classification, custodian agencies, and work plans.',
    NULL,
    '{"Indicators"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'indicators')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Assessment')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Central Statistics Office of Ireland',
    'Ireland Update on SDG Reporting',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/8.%20Ireland%20SDG%20Monitoring%20and%20Implementation.pdf',
    'An overview of Ireland''s reporting platform, developed in partnership with Esri. The presentation outlines key functional features of the site, key stakeholders and their roles.',
    'IRL',
    '{"Ireland", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Central Statistics Office of India',
    'Sustainable Development Goals - Indian Status',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/8.%20India%20SDG%20Implementation.pdf',
    'An overview of India''s SDG data roadmap.',
    'IND',
    '{"India"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Philippine Statistics Authority',
    'Sustainable Development Goals: Implementation and Reporting in the Philippines',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/8.%20Philippines%20SDG%20Implementation%20and%20Reporting.pdf',
    'A summary of current and future SDG reporting efforts in the Philippines',
    'PHL',
    '{"Philippines"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'National Statistics Institute of Cameroon',
    'SDG Reporting Mechanism and Process in Cameroon',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/8.%20Cameroon%20SDG%20Reporting%20and%20Implementation.pdf',
    'A summary of Cameroon''s current and future plans to report on the SDG indicators',
    'CMR',
    '{"Cameroon"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Brazilian Institute of Geography and Statistics (IBGE)',
    'SDG Indicators in Brazil',
    'https://unstats.un.org/sdgs/files/meetings/iaeg-sdgs-meeting-06/8.%20Brazil%20SDG%20Monitoring%20and%20Implementation.pdf',
    'A summary of Brazil''s current and future plans to report on the SDG indicators.',
    'BRA',
    '{"Brazil"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    NULL,
    'Introduction to GitHub for Newcomers',
    'https://www.youtube.com/watch?v=uNa9GOtM6NE',
    'An introduction to using Github.com for version control and issue tracking.',
    NULL,
    '{"Github", "Open source", "Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'versioncontrol')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    NULL,
    'Introduction to GitLab Workflow',
    'https://www.youtube.com/watch?v=enMumwvLAug',
    'An introduction to using Gitlab for version control and issue tracking.',
    NULL,
    '{"Gitlab", "Open source", "Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'versioncontrol')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    NULL,
    'Introduction to Bitbucket',
    'https://www.youtube.com/watch?v=7vOgKcG5mw8',
    'An introduction to using Bitbucket.org for version control and issue tracking.',
    NULL,
    '{"Bitbucket", "Open source", "Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'versioncontrol')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'How do we create our own NRP',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/How-do-we-create-our-own-NRP',
    'Forking guidance for the UK national reporting platform.',
    'GBR',
    '{"United Kingdom", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'forking')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'US Office of the Chief Statistician',
    'How do we create our own NRP',
    'https://github.com/GSA/sdg-indicators/wiki/How-do-we-create-our-own-NRP',
    'Forking guidance for the US national reporting platform.',
    'USA',
    '{"United States", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'forking')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'US Office of the Chief Statistician',
    'How do we put our own statistics into the NRP',
    'https://github.com/GSA/sdg-indicators/wiki/How-do-we-put-our-own-statistics-into-the-NRP',
    'Data entry guidance for the US national reporting platform.',
    'USA',
    '{"United States", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'addingdata')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'Raw data format',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/Raw-data-format',
    'Explanation of the data format used in the UK national reporting platform.',
    'GBR',
    '{"United Kingdom", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'addingdata')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'Metadata format',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/Metadata-format',
    'Explanation of the metadata format used in the UK national reporting platform.',
    'GBR',
    '{"United Kingdom", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'addingdata')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'Permissions for Adding Data',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/Permissions-for-Adding-Data',
    'Explanation of the permissions system for entering data in the UK national reporting platform.',
    'GBR',
    '{"United Kingdom", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'customization')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'addingdata')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'Data scenarios and characteristics',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/Data-scenarios-and-characteristics',
    'Explanation of the supported types of visualizations and disaggregations in the UK national reporting platform.',
    'GBR',
    '{"United Kingdom", "Open source", "National Reporting Platform", "Disaggregation"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'customization')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Global Partnership for Sustainable Development Data (GPSDD)',
    'API Highways',
    'http://apihighways.data4sdgs.org/',
    'Proof-of-concept website providing API access to SDG data.',
    NULL,
    '{"Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'What do we need to change',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/What-do-we-need-to-change',
    'Explanation of how to customise the UK national reporting platform for use by other countries.',
    'GBR',
    '{"United Kingdom", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'customization')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'UK Office for National Statistics',
    'Differences between US and UK NRPs',
    'https://github.com/datasciencecampus/sdg-indicators/wiki/Differences-between-the-US-and-UK-NRPs',
    'List of differences between the US and UK national reporting platforms.',
    'GBR',
    '{"United Kingdom", "United States", "Open source", "National Reporting Platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'customization')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'United Nations',
    'Voluntary National Reviews Database',
    'https://sustainabledevelopment.un.org/vnrs/',
    'An online platform compiling information from countries participating in the voluntary national reviews of the High-level Political Forum on Sustainable Development.',
    NULL,
    '{"Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'United Nations',
    'Resolution adopted by the General Assembly on 25 September 2015',
    'http://www.un.org/en/development/desa/population/migration/generalassembly/docs/globalcompact/A_RES_70_1_E.pdf,2015-10-21',
    'The UN Resolution adopted by the General Assembly for the 2030 Agenda for Sustainable Development.',
    NULL,
    '2015-10-21 00:00:00',
    '{"Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'intro')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'PARIS21',
    'Realising the Data Revolution for Sustainable Development: Towards Capacity Development 4.0',
    'https://www.paris21.org/sites/default/files/CapacityDevelopment4.0_FINAL_0.pdf',
    'This document outlines a vision improving support for and increasing statistical capacity development',
    NULL,
    '2017-01-01 00:00:00',
    '{"Capacity"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'capacity')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Open Knowledge International',
    'Frictionless Data',
    'https://frictionlessdata.io',
    'Open-source software that can be used to standardize and improve the quality of data.',
    NULL,
    '{"Open source", "Standards", "Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE)',
    'Generic Statistical Business Process Model',
    'https://statswiki.unece.org/display/GSBPM/GSBPM+v5.0,2013-12',
    'This document describes and defines the set of business processes needed to produce official statistics.',
    NULL,
    '2013-12-01 00:00:00',
    '{"Data"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'OECD',
    '.Stat Suite',
    'https://siscc.oecd.org/Home/Product?Length=4',
    'An SDMX based modular platform covering the complete end-to-end data lifecycle to build tailored data portals and reporting platforms.',
    NULL,
    '{"Data", "Standards", "Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'OECD',
    'Statistical Information System Collaboration Community',
    'https://siscc.oecd.org',
    'A community of .Stat users which was setup so that participating members could share experiences, knowledge, and best practices.',
    NULL,
    '{"Engagement"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'engagement')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Community Systems Foundation (CSF)',
    'Data For All',
    'https://info.dataforall.org',
    'This platform provides a range of open-source tools for data capture, management, and analysis to help countries develop custom, modular platforms for monitoring their national development.',
    NULL,
    '{"Open source", "Standards", "Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Data Act Lab',
    'Data Act Lab',
    'http://dataactlab.com/',
    'Solutions that deliver powerful visualizations to help actors make sense of complex data.',
    NULL,
    '{"Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'African Development Bank Group',
    'Africa Information Highway',
    'http://sdg.opendataforafrica.org',
    'An SDG reporting platform for African countries.',
    NULL,
    '{"Regional platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'approaches')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Eurostat',
    'Eurostat Overview of the Sustainable Development Goals',
    'http://ec.europa.eu/eurostat/web/sdi/overview',
    'An SDG reporting platform for European countries.',
    NULL,
    '{"Regional platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'approaches')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, tags) VALUES    
  (
    'Asia Pacific SDG Partnership',
    'Asia Pacific SDG Partnership',
    'http://data.unescap.org/sdg/',
    'An SDG reporting platform for countries in Asia and the Pacific.',
    NULL,
    '{"Regional platform"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'approaches')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Statistics Institute of Belize',
    'Contribution of the Belize National Statistical System to National SDG Review & Reporting Systems',
    'https://www.cepal.org/sites/default/files/presentations/si-dcastillotrejo-contribution-belize-nationalsdg-review.pdf',
    'An overview of coordination processes on SDG reporting in Belize.',
    'BLZ',
    '2017-04-01 00:00:00',
    '{"Belize"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Presentation')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);

-- Set all resources to be published.
UPDATE sdg.resource SET publish = true;



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE), Conference of European Statisticians'' Steering Group on Statistics for SDGs',
    'Statistics for SDGs Wiki',
    'https://statswiki.unece.org/display/SFSDG',
    'The Wiki provides links to materials that become available during the Steering Group''s work and that can be useful for countries and organization in the work related to statistics for SDGs.',
    NULL,
    NULL,
    '{"Policy", "Data", "Capacity"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Global Partnership for Sustainable Development Data (GPSDD)',
    'Data4SDGs Toolbox',
    'http://www.data4sdgs.org/initiatives/data4sdgs-toolbox',
    'A set of tools, methods, and resources to help countries to create and implement their own holistic data roadmaps for sustainable development.',
    NULL,
    NULL,
    '{"Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'UN Economic Comission for Europe (UNECE), Conference of European Statisticians'' Steering Group on Statistics for SDGs',
    'National Reporting Platforms, Practical Guide',
    'https://statswiki.unece.org/display/SFSDG/Task+Force+on+National+Reporting+Platforms?preview=/128451803/170164503/NRP_practical%2520guide_Note%2520from%2520UNCES%2520SG%2520SDG%2520TF%2520NRP.pdf',
    'A document aimed to help countries in deciding whether and how to set up a National Reporting Platform (NRP).',
    NULL,
    '2018-01-17 00:00:00',
    '{"Policy", "National Reporting Platform", "Data"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'policy')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert2),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Open Data Watch',
    'Open Data Inventory',
    'http://odin.opendatawatch.com/',
    'ODIN assesses the coverage and openness of official statistics to help identify gaps, promote open data policies, improve access, and encourage dialogue between national statistical offices (NSOs) and data users.',
    NULL,
    NULL,
    '{"Open data", "Data"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'assessment')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  ),
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'William and Flora Hewlett Foundation',
    'Evidence-Informed Policymaking for Global Development',
    'https://www.hewlett.org/wp-content/uploads/2016/10/Final-EIP-2-pager.pdf',
    'A description of the Hewlett Foundation''s portfolio to support evidence-informed policymaking.',
    NULL,
    NULL,
    '{"Capacity", "Financing"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'intro')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Open Government Partnership',
    'How Can the Open Government Partnership Accelerate Implementation of the 2030 Agenda on Sustainable Development?',
    'http://www.opengovpartnership.org/sites/default/files/attachments/2015_OGP_SDG.pdf',
    'An overview of the role of transparency and governance in achieving the 2030 Agenda.',
    NULL,
    '2015-01-01 00:00:00',
    '{"Open data", "Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Results for America',
    '100+ Government mechanisms to advance the use of data and evidence 
in policymaking: A landscape review',
    'http://results4america.org/wp-content/uploads/2017/08/Landscape_int_FINAL.pdf',
    'A compilation of the strategies and mechanisms that governments across the globe are using to advance and institutionalize the use of data and evidence in policymaking.',
    NULL,
    '2017-07-01 00:00:00',
    '{"Data", "Policy"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'reporting')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Report')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'Organization of American States (OAS)',
    'SDG''s Reporting Platform',
    'http://cooperanet.net/community/groups/profile/1239/sdg039s-reporting-platform',
    'OAS'' platform for member countries to exchange their experiences reporting on the SDGs.',
    NULL,
    NULL,
    '{"Country experience"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'countries')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
),
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'Spanish')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'International Open Data Charter',
    'Resource Centre',
    'https://opendatacharter.net/resource-centre/',
    'Resources to facilitate the increased adoption and implementation of shared open data principles, standards and good practices across sectors around the world.',
    NULL,
    NULL,
    '{"Open data"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'standards')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Website')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);



WITH insert1 AS (
  -- Create resource.
  INSERT INTO sdg.resource (organization, title, url, description, country_id, date_published, tags) VALUES    
  (
    'SocialCops',
    'UN Sustainable Development Goals (SDG) Tracker',
    'https://socialcops.com/sustainable-development-goals-tracker-video-demo/',
    'A demo of  SocialCops'' Tracker Dashboard that can help government agencies to measure, track and align their country''s development efforts with the SDG framework.',
    NULL,
    NULL,
    '{"Technology"}'
  )
  RETURNING uuid
), insert2 AS (
  -- Associate topics.
  INSERT INTO sdg.resource_topics (resource_id, topic_id) VALUES
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'technology')
  ),
  (
    (SELECT uuid FROM insert1),
    (SELECT id FROM sdg.topic WHERE topic = 'features')
  )
  RETURNING *
), insert3 AS (
  -- Associate content types.
  INSERT INTO sdg.resource_content_types (resource_id, content_type_id) VALUES
  (
    (SELECT DISTINCT (resource_id) FROM insert2),
    (SELECT id FROM sdg.content_type WHERE name = 'Video')
  )
  RETURNING *
)
-- Associate languages.
INSERT INTO sdg.resource_languages (resource_id, language_id) VALUES
(
  (SELECT DISTINCT (resource_id) FROM insert3),
  (SELECT ietf_tag FROM sdg.language WHERE name = 'English')
);

-- Set all initial resources to be published by default.
UPDATE sdg.resource SET publish = true;

/**
 * Load initial news articles.
 */
INSERT INTO sdg.news (title, organization, url, description) VALUES
(
  'Sustainable Development Goals: progress and possibilities: November 2017',
  'UK Office of National Statistics',
  'https://www.ons.gov.uk/economy/environmentalaccounts/articles/sustainabledevelopmentgoalstakingstockprogressandpossibilities/november2017',
  'Publication of the first report on progress made towards measuring the global Sustainable Development Goal indicators in the UK.'
),
(
  'Announcing the SDG National Reporting Initiative',
  'Center for Open Data Enterprise',
  'https://www.huffingtonpost.com/entry/59c04fb8e4b082fd4205b948',
  'Launch of the SDG National Reporting Initiative to support government reporting on the SDGs for data-driven policymaking.'
);

/**
 * Load initial events.
 */
INSERT INTO sdg.event (title, url, start_time, end_time, locations) VALUES
('GPSDD: Data for Development Festival', 'http://www.data4sdgs.org/news/data-development-festival', '2018-03-21 09:00:00+00', '2018-03-23 17:00:00+00', '{"Bristol, UK"}'),
('UN Seminar on Open Data & SDGs', 'https://unstats.un.org/sdgs/meetings/sdg-seminar-seoul-2017/', '2017-09-26 00:00:00+00', '2017-09-28 00:00:00+00', '{"Seoul, South Korea"}'),
('National Platforms for SDG Reporting - Identifying Best Practices and Solutions', 'https://unstats.un.org/unsd/capacity-building/meetings/National_Platforms_for_SDGs', '2018-01-22 00:00:00+00', '2018-01-24 00:00:00+00', '{"New York, USA"}');

