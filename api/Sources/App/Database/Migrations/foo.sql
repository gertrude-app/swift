-- releases, stripe_events

--

CREATE TYPE release_channels AS ENUM (
    'stable',
    'beta',
    'canary'
);

-- tables

CREATE TABLE releases (
    id uuid NOT NULL,
    semver text NOT NULL,
    channel release_channels NOT NULL,
    signature text NOT NULL,
    length integer NOT NULL,
    app_revision text NOT NULL,
    core_revision text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE stripe_events (
    id uuid NOT NULL,
    json text NOT NULL,
    created_at timestamp with time zone NOT NULL
);

-- constraints

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_semver_key UNIQUE (semver);

ALTER TABLE ONLY stripe_events
    ADD CONSTRAINT stripe_events_pkey PRIMARY KEY (id);

