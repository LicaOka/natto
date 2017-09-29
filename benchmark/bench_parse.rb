# -*- coding: utf-8 -*-
$: << "lib" 
require "benchmark"

require "MeCab"
require "../lib/natto/natto"

require "memprof2"

@mecab_tagger = MeCab::Tagger.new
@natto_mecab = Natto::MeCab.new("-N 3 -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd")

def run(n)
  GC.disable
  n.times do
    yield
  end
  GC.enable
end

def run_memprof(n)
  GC.disable
  Memprof2.start
  n.times do
    yield
  end
  Memprof2.report
  Memprof2.stop
  GC.enable
end

def benchmark(text)
  n = 10000
  puts("\ntext: #{text}")

  Benchmark.bmbm(10) do |job|
    job.report("MeCab") do
      run(n) do
        @mecab_tagger.parse(text)
      end
    end

    job.report("natto.parse") do
      run(n) do
        @natto_mecab.parse(text)
      end
    end

    job.report("parse by threading") do
      #local_tagger  = Natto::MeCab.mecab_model_new_tagger(@natto_mecab.model)
      loop_count = (n/4).to_int
      run(loop_count) do
        threads = 4.times.collect do
          Thread.new do
            @natto_mecab.parse(text.dup) do |nmt|
              #puts nmt
            end
          end
        end
        threads.each(&:join)
      end
    end
  end
  puts

  puts "----- memprof2 -----"
  Memprof2.start
  @mecab_tagger2 = MeCab::Tagger.new
  Memprof2.report
  Memprof2.stop
  puts
  Memprof2.start
  @natto_mecab2 = Natto::MeCab.new("-N 3 -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd")
  Memprof2.report
  Memprof2.stop

  Memprof2.start
  @natto_tagger2  = Natto::MeCab.mecab_model_new_tagger(@natto_mecab2.model)
  Memprof2.report
  Memprof2.stop

  puts "--- mecab ---"
  run_memprof(n) do
    @mecab_tagger2.parse(text)
  end

  puts "--- natto.parse ---"
  run_memprof(n) do
    @natto_mecab2.parse(text)
  end

  puts "--- parse by threading ---"
  loop_count = (n/4).to_int
  run_memprof(loop_count) do
    threads = 4.times.collect do
      Thread.new do
        @natto_mecab2.parse(text.dup)
        end
      end
    threads.each(&:join)
  end
end

benchmark("私の名前は中野です。")
benchmark("すもももももももものうち")
benchmark("MeCabは 京都大学情報学研究科−日本電信電話株式会社コミュニケーション科学基礎研究所 共同研究ユニットプロジェクトを通じて開発されたオープンソース 形態素解析エンジンです. 言語, 辞書,コーパスに依存しない汎用的な設計を 基本方針としています. パラメータの推定に Conditional Random Fields (CRF) を用 いており, ChaSenが採用している 隠れマルコフモデルに比べ性能が向上しています。また、平均的に ChaSen, Juman, KAKASIより高速に動作します. ちなみに和布蕪(めかぶ)は, 作者の好物です.")
benchmark("太郎はこの本を二郎を見た女性に渡した。")
