<?php
    $config_path = "config.prod";
    if ("prod" != getenv("APP_ENV"))
    {
        http_response_code(500);
    }

    echo file_get_contents('./config.prod');