package com.example.tsubuyaki.service;

import com.example.tsubuyaki.domain.Post;
import com.example.tsubuyaki.repository.PostRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    @Mock
    private PostRepository postRepository;

    @InjectMocks
    private PostService postService;

    @Test
    @DisplayName("投稿一覧_最新50件取得_Repositoryの結果を返す")
    void 投稿一覧_最新50件取得_Repositoryの結果を返す() {
        List<Post> posts = List.of(
                new Post("alice", "新しい投稿", LocalDateTime.parse("2026-05-23T10:00:00"))
        );
        given(postRepository.findTop50ByOrderByCreatedAtDesc()).willReturn(posts);

        List<Post> actual = postService.findLatest50();

        assertThat(actual).isSameAs(posts);
    }

    @Test
    @DisplayName("投稿詳細_IDで取得_Repositoryの結果を返す")
    void 投稿詳細_IDで取得_Repositoryの結果を返す() {
        Post post = new Post("alice", "詳細を表示する投稿", LocalDateTime.parse("2026-05-23T10:00:00"));
        given(postRepository.findById(1L)).willReturn(Optional.of(post));

        Optional<Post> actual = postService.findById(1L);

        assertThat(actual).containsSame(post);
    }
}
