package com.agentops.console.service;

public enum BucketGranularity {
    DAY("day"),
    WEEK("week");

    private final String sqlValue;

    BucketGranularity(String sqlValue) {
        this.sqlValue = sqlValue;
    }

    public String sqlValue() {
        return sqlValue;
    }
}
