package com.example.tsubuyaki.repository;

import com.example.tsubuyaki.domain.Post;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<Post, Long> {

    // 演習中に追加するメソッド例:
    //   List<Post> findTop50ByOrderByCreatedAtDesc();
}
