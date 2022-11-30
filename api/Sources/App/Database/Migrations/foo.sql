-- screenshots, keystroke_lines
-- network_decisions, unlock_requests, suspend_filter_requests
-- app_bundle_ids, app_categories, identified_apps
-- releases, stripe_events

CREATE TABLE keystroke_lines (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    app_name text NOT NULL,
    line text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);

ALTER TABLE ONLY keystroke_lines
    ADD CONSTRAINT keystroke_lines_protected_user_id_fkey FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE;

--

CREATE TYPE network_decision_reason AS ENUM (
    'block',
    'allow',
    'systemUser',
    'userIsExempt',
    'missingKeychains',
    'missingUserId',
    'defaultNotAllowed',
    'ipAllowed',
    'domainAllowed',
    'pathAllowed',
    'fileExtensionAllowed',
    'appBlocked',
    'fromGertrudeApp',
    'appUnrestricted',
    'dns',
    'nonDnsUdp',
    'systemUiServerInternal',
    'filterSuspended'
);

CREATE TYPE network_decision_verdict AS ENUM (
    'block',
    'allow',
    'filterSuspended'
);

CREATE TYPE release_channels AS ENUM (
    'stable',
    'beta',
    'canary'
);

CREATE TYPE request_status AS ENUM (
    'accepted',
    'pending',
    'rejected'
);

CREATE TYPE unlock_request_status AS ENUM (
    'pending',
    'accepted',
    'rejected'
);

-- tables

CREATE TABLE _jobs (
    id uuid NOT NULL,
    job_id text NOT NULL,
    queue text NOT NULL,
    data bytea NOT NULL,
    state text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);

CREATE TABLE admin_notifications (
    id uuid NOT NULL,
    admin_id uuid NOT NULL,
    trigger admin_user_notification_trigger NOT NULL,
    created_at timestamp with time zone NOT NULL,
    method_id uuid NOT NULL
);

CREATE TABLE admin_tokens (
    id uuid NOT NULL,
    value uuid NOT NULL,
    admin_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone NOT NULL
);

CREATE TABLE admin_verified_notification_methods (
    id uuid NOT NULL,
    admin_id uuid NOT NULL,
    method jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE TABLE admins (
    id uuid NOT NULL,
    email text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    subscription_id text,
    subscription_status admin_user_subscription_status DEFAULT 'pendingEmailVerification'::admin_user_subscription_status,
    password text NOT NULL
);

CREATE TABLE app_bundle_ids (
    id uuid NOT NULL,
    bundle_id text NOT NULL,
    identified_app_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE app_categories (
    id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE identified_apps (
    id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    selectable boolean NOT NULL,
    category_id uuid,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE network_decisions (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    verdict network_decision_verdict NOT NULL,
    reason network_decision_reason NOT NULL,
    ip_protocol_number bigint,
    hostname text,
    ip_address text,
    url text,
    app_bundle_id text,
    count bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    responsible_key_id uuid
);

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

CREATE TABLE suspend_filter_requests (
    id uuid NOT NULL,
    device_id uuid,
    status request_status NOT NULL,
    scope jsonb NOT NULL,
    duration bigint NOT NULL,
    request_comment text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    response_comment text
);

CREATE TABLE unlock_requests (
    id uuid NOT NULL,
    network_decision_id uuid NOT NULL,
    device_id uuid NOT NULL,
    request_comment text,
    response_comment text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status request_status NOT NULL
);

-- constraints

ALTER TABLE ONLY _jobs
    ADD CONSTRAINT _jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admin_notifications
    ADD CONSTRAINT admin_user_notifications_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admin_tokens
    ADD CONSTRAINT admin_user_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admins
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admin_verified_notification_methods
    ADD CONSTRAINT admin_verified_notification_methods_pkey PRIMARY KEY (id);

ALTER TABLE ONLY app_bundle_ids
    ADD CONSTRAINT app_bundle_ids_pkey PRIMARY KEY (id);

ALTER TABLE ONLY app_categories
    ADD CONSTRAINT app_categories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY identified_apps
    ADD CONSTRAINT identified_apps_pkey PRIMARY KEY (id);

ALTER TABLE ONLY network_decisions
    ADD CONSTRAINT network_decisions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_semver_key UNIQUE (semver);

ALTER TABLE ONLY stripe_events
    ADD CONSTRAINT stripe_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY suspend_filter_requests
    ADD CONSTRAINT suspend_filter_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admin_verified_notification_methods
    ADD CONSTRAINT unique_admin_id_method UNIQUE (admin_id, method);

ALTER TABLE ONLY admin_notifications
    ADD CONSTRAINT unique_method_id_trigger_admin_id UNIQUE (method_id, trigger, admin_id);

ALTER TABLE ONLY unlock_requests
    ADD CONSTRAINT unlock_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admin_tokens
    ADD CONSTRAINT "uq:admin_user_tokens.value" UNIQUE (value);

ALTER TABLE ONLY admins
    ADD CONSTRAINT "uq:admin_users.email" UNIQUE (email);

ALTER TABLE ONLY app_bundle_ids
    ADD CONSTRAINT "uq:app_bundle_ids.bundle_id" UNIQUE (bundle_id);

ALTER TABLE ONLY app_categories
    ADD CONSTRAINT "uq:app_categories.name" UNIQUE (name);

ALTER TABLE ONLY app_categories
    ADD CONSTRAINT "uq:app_categories.slug" UNIQUE (slug);

ALTER TABLE ONLY identified_apps
    ADD CONSTRAINT "uq:identified_apps.name" UNIQUE (name);

ALTER TABLE ONLY identified_apps
    ADD CONSTRAINT "uq:identified_apps.slug" UNIQUE (slug);

ALTER TABLE ONLY admin_notifications
    ADD CONSTRAINT admin_user_notifications_admin_user_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE;

ALTER TABLE ONLY admin_tokens
    ADD CONSTRAINT admin_user_tokens_admin_user_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE;

ALTER TABLE ONLY admin_verified_notification_methods
    ADD CONSTRAINT admin_verified_notification_methods_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE;

ALTER TABLE ONLY app_bundle_ids
    ADD CONSTRAINT app_bundle_ids_identified_app_id_fkey FOREIGN KEY (identified_app_id) REFERENCES identified_apps(id) ON DELETE CASCADE;

ALTER TABLE ONLY admin_notifications
    ADD CONSTRAINT fk_admin_notification_method_id FOREIGN KEY (method_id) REFERENCES admin_verified_notification_methods(id);

ALTER TABLE ONLY identified_apps
    ADD CONSTRAINT identified_apps_app_category_id_fkey FOREIGN KEY (category_id) REFERENCES app_categories(id) ON DELETE CASCADE;

ALTER TABLE ONLY network_decisions
    ADD CONSTRAINT network_decisions_protected_user_id_fkey FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE;

ALTER TABLE ONLY network_decisions
    ADD CONSTRAINT network_decisions_responsible_key_id_fkey FOREIGN KEY (responsible_key_id) REFERENCES keys(id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY suspend_filter_requests
    ADD CONSTRAINT suspend_filter_requests_protected_user_id_fkey FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE;

ALTER TABLE ONLY unlock_requests
    ADD CONSTRAINT unlock_requests_network_decision_id_fkey FOREIGN KEY (network_decision_id) REFERENCES network_decisions(id) ON DELETE CASCADE;

ALTER TABLE ONLY unlock_requests
    ADD CONSTRAINT unlock_requests_protected_user_id_fkey FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE;

-- indexes

CREATE INDEX i__jobs_job_id ON _jobs USING btree (job_id);

CREATE INDEX i__jobs_state_queue ON _jobs USING btree (state, queue);

