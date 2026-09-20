package com.agentops.console;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Testcontainers
class MigrationIntegrationTest {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void flywayAppliesAllMigrations() {
        Integer applied = jdbc.queryForObject(
                "SELECT count(*) FROM flyway_schema_history WHERE success", Integer.class);
        assertThat(applied).isEqualTo(3);
    }

    @Test
    void seedDataIsPresent() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM prompt_variant", Integer.class)).isEqualTo(8);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM agent_run", Integer.class)).isEqualTo(40);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM patch", Integer.class)).isEqualTo(200);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM review_verdict", Integer.class)).isEqualTo(140);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM review_audit", Integer.class)).isZero();
    }

    @Test
    void dashboardIndexesExist() {
        Integer count = jdbc.queryForObject("""
                SELECT count(*)
                FROM pg_indexes
                WHERE indexname IN ('idx_agent_run_started_at',
                                    'idx_agent_run_variant_started_at',
                                    'idx_patch_run_id',
                                    'idx_review_verdict_decision_decided_at',
                                    'idx_review_audit_patch_changed_at')
                """, Integer.class);
        assertThat(count).isEqualTo(5);
    }

    @Test
    @org.springframework.transaction.annotation.Transactional
    void cascadeDeleteRemovesPatchesAndVerdicts() {
        jdbc.update("DELETE FROM agent_run WHERE status = 'FAILED'");
        Integer orphanPatches = jdbc.queryForObject(
                "SELECT count(*) FROM patch p WHERE NOT EXISTS (SELECT 1 FROM agent_run r WHERE r.id = p.run_id)",
                Integer.class);
        Integer orphanVerdicts = jdbc.queryForObject(
                "SELECT count(*) FROM review_verdict rv WHERE NOT EXISTS (SELECT 1 FROM patch p WHERE p.id = rv.patch_id)",
                Integer.class);
        Integer orphanAudits = jdbc.queryForObject(
                "SELECT count(*) FROM review_audit ra WHERE NOT EXISTS (SELECT 1 FROM patch p WHERE p.id = ra.patch_id)",
                Integer.class);
        assertThat(orphanPatches).isZero();
        assertThat(orphanVerdicts).isZero();
        assertThat(orphanAudits).isZero();
    }
}
