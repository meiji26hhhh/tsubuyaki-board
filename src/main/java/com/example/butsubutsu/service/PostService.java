package com.example.butsubutsu.service;

import com.example.butsubutsu.domain.Post;
import com.example.butsubutsu.repository.PostRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class PostService {

    private final PostRepository repository;

    public PostService(PostRepository repository) {
        this.repository = repository;
    }

    public List<Post> latest() {
        // TODO: 演習で実装する (最新 50 件を新着順で返す)
        return Collections.emptyList();
    }
}
