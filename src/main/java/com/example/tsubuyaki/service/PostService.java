package com.example.tsubuyaki.service;

import com.example.tsubuyaki.domain.Post;
import com.example.tsubuyaki.domain.PostLike;
import com.example.tsubuyaki.repository.PostLikeRepository;
import com.example.tsubuyaki.repository.PostRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class PostService {

    private final PostRepository repository;
    private final PostLikeRepository likeRepository;

    public PostService(PostRepository repository, PostLikeRepository likeRepository) {
        this.repository = repository;
        this.likeRepository = likeRepository;
    }

    public List<Post> latest() {
        return findLatest50();
    }

    public List<Post> findLatest50() {
        return repository.findTop50ByOrderByCreatedAtDesc();
    }

    public Optional<Post> findById(Long id) {
        return repository.findById(id);
    }

    public long countLikes(Long postId) {
        return likeRepository.countByPost_Id(postId);
    }

    @Transactional
    public Post create(String author, String body) {
        return repository.save(new Post(author, body, LocalDateTime.now()));
    }

    @Transactional
    public void toggleLike(Long postId, String clientHash) {
        if (likeRepository.existsByPost_IdAndClientHash(postId, clientHash)) {
            likeRepository.deleteByPost_IdAndClientHash(postId, clientHash);
            return;
        }
        Post post = repository.findById(postId).orElseThrow();
        likeRepository.save(new PostLike(post, clientHash, LocalDateTime.now()));
    }
}
