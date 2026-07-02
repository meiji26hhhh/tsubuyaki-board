package com.example.tsubuyaki.repository;

import com.example.tsubuyaki.domain.Post;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("h2")
class PostRepositoryTest {

    @Autowired
    private PostRepository postRepository;

    @Test
    @DisplayName("投稿一覧_51件保存済み_最新50件を新着順で返す")
    void 投稿一覧_51件保存済み_最新50件を新着順で返す() {
        LocalDateTime baseTime = LocalDateTime.parse("2026-05-23T00:00:00");
        List<Post> posts = new ArrayList<>();
        for (int index = 0; index < 51; index++) {
            posts.add(new Post(
                    "user" + index,
                    "body" + index,
                    baseTime.plusSeconds(index)
            ));
        }
        postRepository.saveAll(posts);

        List<Post> actual = postRepository.findTop50ByOrderByCreatedAtDesc();

        assertThat(actual).hasSize(50);
        assertThat(actual)
                .extracting(Post::getBody)
                .containsExactlyElementsOf(expectedBodiesNewestFirst());
    }

    private List<String> expectedBodiesNewestFirst() {
        List<String> bodies = new ArrayList<>();
        for (int index = 50; index >= 1; index--) {
            bodies.add("body" + index);
        }
        return bodies;
    }
}
