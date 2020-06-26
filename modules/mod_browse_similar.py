# !/usr/bin/python
# -*- coding: utf-8 -*-

import ujson
import pickle
import hnswlib
import sqlite3

import numpy as np


class Index:
    def __init__(self, space='l2', dim=1280):
        self.index = self.get_index(space, dim)
        self.labels = self.get_labels()

        indices = range(len(self.labels))

        self.lookup = dict(zip(self.labels, indices))
        self.labels = np.array(self.labels)

    @staticmethod
    def get_index(space, dim):
        index = hnswlib.Index(space=space, dim=dim)
        index.load_index(r'..\data\index.bin', 1000000)

        return index

    @staticmethod
    def get_labels():
        with open(r'..\data\labels.bin', 'rb') as handle:
            labels = pickle.load(handle)

            for idx in range(len(labels)):
                label = labels[idx].decode().split('\\')
                labels[idx] = label[-1].split('.')[0]

        return labels

    def query(self, item, k):
        if item < self.index.get_current_count():
            feature = self.index.get_items([item])

            return self.index.knn_query(feature, k=k)

    def get_similar(self, item, k=10):
        if item in self.lookup:
            indices, _ = self.query(self.lookup[item], 30)
            labels = self.labels[indices.flatten()]

            return list(dict.fromkeys(labels))[1:(int(k) + 1)]

    def save(self, file_name):
        def _commit(document):
            execute = 'INSERT INTO database (id, similar) VALUES (?, ?)'
            file_object.executemany(execute, document)

            file_object.commit()

        with sqlite3.connect(file_name) as file_object:
            file_object.execute('CREATE TABLE database (id, similar)')
            file_object.execute('CREATE INDEX id_idx ON database (id)')

            file_object.commit()
            results = list()

            for label in set(self.labels):
                most_similar = self.get_similar(label, k=10)
                results.append((label, ujson.dumps(most_similar)))

                if len(results) % 25000 == 0:
                    _commit(results)
                    results = list()

            _commit(results)


if __name__ == '__main__':
    Index().save(r'..\data\index.sqlite')
