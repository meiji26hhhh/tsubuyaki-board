package com.example.tsubuyaki;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("h2")
class TsubuyakiApplicationTests {

    @Test
    void contextLoads() {
        // Spring コンテキストが h2 プロファイルで起動できることだけを確認する。
    }
}
