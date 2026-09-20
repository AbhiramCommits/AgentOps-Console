package com.agentops.console.api;

import com.agentops.console.service.BucketGranularity;
import org.springframework.context.annotation.Configuration;
import org.springframework.format.FormatterRegistry;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:5173")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS");
    }

    @Override
    public void addFormatters(FormatterRegistry registry) {
        // The metrics API is specified as bucket=day|week (lowercase).
        registry.addConverter(String.class, BucketGranularity.class,
                source -> BucketGranularity.valueOf(source.trim().toUpperCase()));
    }
}
