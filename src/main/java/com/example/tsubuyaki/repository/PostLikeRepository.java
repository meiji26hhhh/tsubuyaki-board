package com.example.tsubuyaki.repository;

import com.example.tsubuyaki.domain.PostLike;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostLikeRepository extends JpaRepository<PostLike, Long> {

    boolean existsByPost_IdAndClientHash(Long postId, String clientHash);

    void deleteByPost_IdAndClientHash(Long postId, String clientHash);

    long countByPost_Id(Long postId);
}
