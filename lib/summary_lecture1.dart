import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // StreamSubscription을 위해 추가
import 'dart:typed_data';
import 'database_helper.dart';
import 'home.dart';
import 'constants.dart';
import 'ad_helper.dart';
import 'ad_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 학습노트 데이터 (기존과 동일)
final Map<String, Map<String, dynamic>> studyNotes = {
  "1. 고객 응대 상황별 공손한 영어 표현": {
    'description':
        '''- 도움 제안: “May I help you with your baggage?” ‑ help + 목적어 + with + 사물 구조로 공손히 지원 의사를 밝힘.
- 주문 권유: “Would you care for a drink?” → would you care for ~ ? 는 선택·거절을 존중하는 정중한 제안.
- 추가 주문: “I’d like to have another drink.” / “I’ll stick to my usual.” 로 ‘한 잔 더’ 또는 ‘늘 마시던 것’ 요청.
- 스케줄 확인: “Are you free this evening?”으로 약속 가능 여부 파악.
- 투숙 상태 확인: “Are you leaving our hotel?” ‑ 현재진행형으로 예정‧확정된 이동을 묻기.
- 통화 연결 불가 안내: “I’m afraid he is on the phone right now.” → 부정적 정보 전달 시 I’m afraid 완충.
- 사과·안전 확인: 충돌 후 “I’m very sorry. I do hope you are not hurt.”''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 53},
      {'date': '2016년 1월', 'question_id': 55},
      {'date': '2016년 1월', 'question_id': 57},
      {'date': '2016년 4월', 'question_id': 51},
      {'date': '2016년 4월', 'question_id': 52},
      {'date': '2016년 4월', 'question_id': 53},
      {'date': '2016년 7월', 'question_id': 52},
      {'date': '2016년 7월', 'question_id': 53},
    ],
  },
  "2. 예약 현황·계산 방식 안내 표현": {
    'description':
        '''- 예약 마감: “We are fully booked on May 5th.” → fully booked + 날짜/기간 으로 ‘빈자리가 전혀 없음’ 명확히 전달.
- 계산 방식 구분:
• “It’s on me.” / “Let me get this.” / “I’ll pick up the check.” = 내가 계산.
• “Let’s go Dutch.” = 각자 계산.''',
    'related_questions': [
      {'date': '2016년 7월', 'question_id': 51},
      {'date': '2016년 7월', 'question_id': 58},
    ],
  },
  "3. 고객서비스 영어 핵심 문법 포인트": {
    'description':
        '''- help + 사람 + with + 사물: May I help you with your baggage? (you를 help 바로 뒤에 둔다)
- keep + 목적어 + 현재분사: Sorry to have kept you waiting. → ‘~을 …한 상태로 두다’.
- should + 동사원형/be + 형용사: You should be kind to guests.
- be + 동사-ing로 미래 예정 표현: Are you leaving our hotel?
- 병렬 동사 사용: supervise and handle ‑ 의미·형태 일치가 중요.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 51},
      {'date': '2016년 4월', 'question_id': 51},
      {'date': '2016년 4월', 'question_id': 54},
      {'date': '2016년 7월', 'question_id': 52},
      {'date': '2016년 7월', 'question_id': 59},
    ],
  },
  "4. 와인 감상·서비스 기본": {
    'description':
        '''- 감상 3요소: Color(시각) ‑ Aroma/Nose(후각) ‑ Taste(미각). Touch는 포함되지 않는다.
- 기본 용어
• Balance: 산도·당도·탄닌·알코올의 조화.
• Nose: 와인의 향.
• Body: 질감·무게감.
• Dry: 잔당이 거의 없어서 단맛이 느껴지지 않는 상태.
- 서비스 원칙
• 적정 온도: 레드 16-18 ℃ / 화이트 8-12 ℃.
• 잔 채우기: 1/3–1/2 수준으로 향 발산 공간 확보.
• 라벨을 손님에게 보여 확인받는다.
- 특별 와인
• Ice Wine: ‑8 ℃ 이하에서 얼린 포도를 즉시 압착해 만든 고당도 디저트 와인.
• Beaujolais Nouveau: 그해 가메(Gamay) 포도로 만든 신주, 매년 11월 셋째 목요일 출시.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 52},
      {'date': '2016년 4월', 'question_id': 57},
      {'date': '2016년 4월', 'question_id': 60},
      {'date': '2016년 7월', 'question_id': 55},
      {'date': '2016년 7월', 'question_id': 56},
    ],
  },
  "5. 증류주·리큐어의 원료와 분류": {
    'description':
        '''- Tequila: 블루 아가베 발효주를 증류한 멕시코 증류주.
- Rum: 사탕수수 당밀/주스 증류주로 열대 칵테일의 대표 베이스.
- Whiskey: 보리·옥수수 등 곡물 증류 후 오크 숙성.
- Gin: 중성 증류주에 주니퍼 베리 등 보타니컬을 가향.
- Calvados: 사과(배) 사이더를 증류한 브랜디 → 포도 원료 아님.
- Cointreau: 오렌지 껍질 향의 트리플 섹 리큐어 → 가당·가향으로 ‘순수 증류주’에서 제외.
- Amaretto: 달콤한 아몬드 풍미의 이탈리아 리큐어.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 56},
      {'date': '2016년 1월', 'question_id': 59},
      {'date': '2016년 1월', 'question_id': 60},
      {'date': '2016년 4월', 'question_id': 56},
      {'date': '2016년 4월', 'question_id': 58},
      {'date': '2016년 4월', 'question_id': 59},
      {'date': '2016년 7월', 'question_id': 54},
    ],
  },
  "6. 칵테일 유형·조주 기법과 대표 레시피": {
    'description':
        '''- Stirring 기법: Mixing Glass + Bar Spoon + Strainer 사용, Shaker는 해당 없음.
- Aperitif(식전) vs Digestif(식후)
• Dry Martini, Kir, Campari Orange = 식전.
• Grasshopper = 크림·민트 리큐어 기반 식후용.
- Layered Cocktail(Pousse café): 비중 차를 이용해 리큐어를 층으로 쌓음.
- 대표 레시피 ‑ Pink Lady: Dry Gin + Egg White + Grenadine (+ Lemon juice) → 크리미하고 연분홍 색.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 54},
      {'date': '2016년 4월', 'question_id': 55},
      {'date': '2016년 7월', 'question_id': 57},
      {'date': '2016년 7월', 'question_id': 60},
    ],
  },
};

class SummaryLecture1Page extends StatefulWidget {
  final String dbPath;

  SummaryLecture1Page({required this.dbPath});

  @override
  _SummaryLecture1PageState createState() => _SummaryLecture1PageState();
}

class _SummaryLecture1PageState extends State<SummaryLecture1Page>
    with WidgetsBindingObserver {
  late DatabaseHelper dbHelper;
  bool isLoading = false;

  // 오디오 플레이어 관련 변수
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isAudioLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _errorMessage = '';
  final List<double> _speedOptions = [0.8, 1.0, 1.2, 1.5, 2.0];
  double _currentSpeed = 1.0;
  bool _isAudioInitialized = false; // 오디오 초기화 상태 추가

  // 오디오 플레이어 리스너 구독을 관리하기 위한 변수 추가
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _processingStateSubscription;

  // 테스트 모드 관련 변수 추가
  bool _isTestMode = false;
  Timer? _testModeTimer;
  static const Duration _testModeDuration = Duration(seconds: 10);

  // 광고 관련 변수 추가
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  int _lastAdShowTime = 0;
  final int _adInterval = 240;
  bool _isAdShowing = false;
  bool _wasPlayingBeforeAd = false;
  int _adRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 테스트 모드 감지
    _isTestMode =
        const bool.fromEnvironment('DISABLE_ADS', defaultValue: false);
    print('SummaryLecture1Page: Test mode enabled: $_isTestMode');

    dbHelper = DatabaseHelper(widget.dbPath);

    // 오디오 초기화를 별도로 실행하여 UI 렌더링을 차단하지 않도록 함
    _initAudioPlayerAsync();

    // 광고 로드는 별도로 실행
    Future.microtask(() {
      if (mounted) {
        _loadInterstitialAd();
      }
    });
  }

  // 오디오 초기화를 비동기로 처리
  void _initAudioPlayerAsync() {
    // UI는 즉시 표시되도록 하고, 오디오 초기화는 백그라운드에서 처리
    Future.microtask(() async {
      if (mounted) {
        await _initAudioPlayer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 테스트 모드 타이머 정리
    _cancelTestModeTimer();

    // 가장 먼저 오디오 플레이어 중지 및 구독 취소
    _audioPlayer.stop(); // 플레이를 즉시 멈춤
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processingStateSubscription?.cancel();
    _processingStateSubscription = null;

    _audioPlayer.dispose(); // 그 다음 플레이어 리소스 해제
    dbHelper.dispose();
    _interstitialAd?.dispose(); // 광고 리소스 해제
    super.dispose();
  }

  // 테스트 모드 타이머 시작
  void _startTestModeTimer() {
    if (!_isTestMode) return;

    _cancelTestModeTimer(); // 기존 타이머가 있다면 취소

    print(
        'SummaryLecture1Page: Starting test mode timer: ${_testModeDuration.inSeconds} seconds');
    _testModeTimer = Timer(_testModeDuration, () {
      print('SummaryLecture1Page: Test mode timer expired - stopping audio');
      if (mounted && _isPlaying) {
        _audioPlayer.pause();
      }
    });
  }

  // 테스트 모드 타이머 취소
  void _cancelTestModeTimer() {
    if (_testModeTimer != null) {
      print('SummaryLecture1Page: Cancelling test mode timer');
      _testModeTimer!.cancel();
      _testModeTimer = null;
    }
  }

  void _loadInterstitialAd() {
    if (!mounted) return; // 메서드 시작 시 mounted 확인

    print("DEBUG: 전면 광고 로드 시도 (시도 횟수: $_adRetryCount)");
    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      print("DEBUG: 광고 제거됨 또는 테스트 모드임");
      return;
    }

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            // 콜백 내에서도 mounted 확인
            ad.dispose(); // 로드되었지만 페이지가 사라졌으면 광고도 해제
            return;
          }
          print("DEBUG: 전면 광고 로드 성공");
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            _adRetryCount = 0;
          });

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (!mounted) return;
              print("DEBUG: 광고 닫힘");
              ad.dispose();
              setState(() {
                _isInterstitialAdLoaded = false;
                _isAdShowing = false;
              });

              if (_wasPlayingBeforeAd) {
                _audioPlayer.play();
              }

              if (!adState.adsRemoved && !kDisableAdsForTesting) {
                if (mounted) _loadInterstitialAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (!mounted) return;
              print("DEBUG: 광고 표시 실패: $error");
              ad.dispose();
              setState(() {
                _isInterstitialAdLoaded = false;
                _isAdShowing = false;
              });

              if (_wasPlayingBeforeAd) {
                _audioPlayer.play();
              }

              if (!adState.adsRemoved && !kDisableAdsForTesting) {
                if (mounted) _loadInterstitialAd();
              }
            },
            onAdShowedFullScreenContent: (ad) {
              print("DEBUG: 광고 전체화면으로 표시됨");
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          print('DEBUG: 전면 광고 로드 실패: $error');
          setState(() => _isInterstitialAdLoaded = false);

          _adRetryCount++;
          Future.delayed(Duration(seconds: 30), () {
            if (mounted) _loadInterstitialAd();
          });

          if (_isAdShowing && _wasPlayingBeforeAd) {
            if (mounted) {
              setState(() => _isAdShowing = false);
              _audioPlayer.play();
            }
          }
        },
      ),
    );
  }

  // _initAudioPlayer 메서드를 다음과 같이 완전히 교체하세요:

  Future<void> _initAudioPlayer() async {
    try {
      print('DEBUG: 오디오 플레이어 초기화 시작');

      if (!mounted) return;

      setState(() {
        _isAudioLoading = true;
        _errorMessage = '';
      });

      // 방법 1: AssetSource 직접 사용 (가장 권장되는 방법)
      try {
        print('DEBUG: AssetSource로 오디오 로딩 시도');

        // 경로에서 'assets/' 제거하고 시도
        await _audioPlayer.setAudioSource(
          AudioSource.asset('audio/summary/lecture1.mp3'),
          preload: true,
        );
        print('DEBUG: AssetSource 오디오 로딩 성공');
      } catch (assetError) {
        print('DEBUG: AssetSource 실패: $assetError');

        // 방법 2: 다른 경로로 시도
        try {
          print('DEBUG: 전체 경로로 AssetSource 시도');
          await _audioPlayer.setAudioSource(
            AudioSource.asset('assets/audio/summary/lecture1.mp3'),
            preload: true,
          );
          print('DEBUG: 전체 경로 AssetSource 성공');
        } catch (fullPathError) {
          print('DEBUG: 전체 경로도 실패: $fullPathError');

          // 방법 3: BytesAudioSource (마지막 수단)
          try {
            print('DEBUG: BytesAudioSource로 fallback 시도');
            final ByteData data =
                await rootBundle.load('assets/audio/summary/lecture1.mp3');
            print('DEBUG: 오디오 파일 로드 성공, 크기: ${data.lengthInBytes} bytes');

            if (!mounted) return;

            final Uint8List bytes = data.buffer.asUint8List();

            // BytesAudioSource 사용 시 preload 제거
            await _audioPlayer.setAudioSource(BytesAudioSource(bytes));
            print('DEBUG: BytesAudioSource 오디오 설정 완료');
          } catch (bytesError) {
            print('DEBUG: BytesAudioSource도 실패: $bytesError');

            // 방법 4: 임시 파일로 저장 후 로드
            try {
              print('DEBUG: 임시 파일 방식 시도');
              await _loadAudioFromTempFile();
              print('DEBUG: 임시 파일 방식 성공');
            } catch (tempError) {
              print('DEBUG: 모든 방법 실패: $tempError');
              throw Exception('모든 오디오 로딩 방법이 실패했습니다: $tempError');
            }
          }
        }
      }

      if (!mounted) return;

      // 성공적으로 로드된 경우에만 리스너 설정
      await _setupAudioListeners();
      await _audioPlayer.setSpeed(_currentSpeed);

      if (!mounted) return;

      setState(() {
        _isAudioLoading = false;
        _isAudioInitialized = true;
      });

      print('DEBUG: 오디오 플레이어 초기화 완료');
    } catch (e) {
      print("DEBUG: 오디오 초기화 전체 오류: $e");
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _errorMessage = '오디오 초기화 오류: $e';
          _isAudioInitialized = false;
        });
      }
    }
  }

// 임시 파일을 사용한 오디오 로딩 메서드 추가
  Future<void> _loadAudioFromTempFile() async {
    final ByteData data =
        await rootBundle.load('assets/audio/summary/lecture1.mp3');
    final Uint8List bytes = data.buffer.asUint8List();

    // 임시 디렉토리에 파일 저장
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File('${tempDir.path}/temp_lecture1.mp3');
    await tempFile.writeAsBytes(bytes);

    // 임시 파일로부터 오디오 로드
    await _audioPlayer.setAudioSource(AudioSource.file(tempFile.path));

    print('DEBUG: 임시 파일에서 오디오 로드 완료: ${tempFile.path}');
  }

// 오디오 리스너 설정을 별도 메서드로 분리
  Future<void> _setupAudioListeners() async {
    // 기존 구독이 있다면 취소
    await _cancelAudioSubscriptions();

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.playing != _isPlaying) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((d) {
      if (!mounted) return;
      if (d != null) {
        setState(() => _duration = d);
        print('DEBUG: 오디오 길이 설정: ${d.inMinutes}:${d.inSeconds % 60}');
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);

      int currentPositionInSeconds = p.inSeconds;
      if (_isPlaying &&
          _isInterstitialAdLoaded &&
          !_isAdShowing &&
          currentPositionInSeconds > 0 &&
          currentPositionInSeconds - _lastAdShowTime >= _adInterval) {
        print(
            "DEBUG: 광고 표시 조건 충족. 현재 시간: $currentPositionInSeconds, 마지막 광고 시간: $_lastAdShowTime");
        if (mounted) {
          setState(() {
            _isAdShowing = true;
            _wasPlayingBeforeAd = _isPlaying;
          });
        }
        _audioPlayer.pause();
        _lastAdShowTime = currentPositionInSeconds;
        if (mounted) _showInterstitialAd();
      }
    });

    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) {
      if (!mounted) return;
      if (state == ProcessingState.completed) {
        _cancelTestModeTimer();
        setState(() {
          _isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

// 구독 취소 메서드
  Future<void> _cancelAudioSubscriptions() async {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processingStateSubscription?.cancel();
    _processingStateSubscription = null;
  }

  void _showInterstitialAd() {
    if (!mounted) return; // 메서드 시작 시 mounted 확인

    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      print("DEBUG: 광고 표시 스킵 - 광고 제거됨 또는 테스트 모드");
      if (mounted) setState(() => _isAdShowing = false);
      if (_wasPlayingBeforeAd) {
        _audioPlayer.play();
      }
      return;
    }

    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      print("DEBUG: 광고 표시 실패 - 광고가 로드되지 않음");
      if (mounted) setState(() => _isAdShowing = false);
      if (_wasPlayingBeforeAd) {
        _audioPlayer.play();
      }
      if (mounted) _loadInterstitialAd();
      return;
    }

    print("DEBUG: 전면 광고 표시 시도");
    _interstitialAd!.show().catchError((error) {
      print("DEBUG: 광고 표시 중 오류 발생: $error");
      if (mounted) {
        setState(() => _isAdShowing = false);
        if (_wasPlayingBeforeAd) {
          _audioPlayer.play();
        }
        _loadInterstitialAd();
      }
    });
  }

  void _playPause() {
    if (!mounted || !_isAudioInitialized) return;

    if (_audioPlayer.playing) {
      // 일시정지 시 타이머 취소
      _cancelTestModeTimer();
      _audioPlayer.pause();
    } else {
      // 재생 시 테스트 모드에서 타이머 시작
      _audioPlayer.play();
      if (_isTestMode) {
        _startTestModeTimer();
      }
    }
  }

  void _changePlaybackSpeed(double speed) {
    if (!mounted || !_isAudioInitialized) return;
    setState(() {
      _currentSpeed = speed;
    });
    _audioPlayer.setSpeed(speed);
  }

// summary_lecture1.dart 파일

void _showQuestionDialog(BuildContext context, String date, int questionId) async {
  if (!mounted) return;

  // --- 제안해주신 로직 시작 ---

  // 1. 날짜 문자열 정규화 (예: '2022년 04월' -> '2022년 4월')
  // '04월'과 '4월'의 불일치 가능성을 처리합니다.
  final normalizedDate = date.replaceAll(' 0', ' ');

  // 2. 맵핑(constants.dart)을 통해 DB 파일 번호(examSession) 찾기
  int? examSession;
  // reverseRoundMapping은 constants.dart에 정의되어 있다고 가정합니다.
  // 이 파일이 import 되어 있는지 확인하세요. 예: import 'constants.dart';
  reverseRoundMapping.forEach((key, value) {
    if (value == normalizedDate) {
      examSession = key;
    }
  });

  // 맵핑되는 DB가 없으면 사용자에게 알림
  if (examSession == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: "$date"에 해당하는 시험 회차 정보를 찾을 수 없습니다.')),
    );
    return;
  }

  try {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // 3. 해당 DB 파일 경로 지정 (예: question1.db)
    String dbPath = 'assets/question$examSession.db';
    DatabaseHelper questionDb = DatabaseHelper.getInstance(dbPath);

    // 4. 새로 추가한 getQuestion 메서드 호출 (Question_id만 사용)
    final question = await questionDb.getQuestion(questionId);
    
    // --- 로직 종료 ---

    if (!mounted) {
      // questionDb.dispose(); // 개별 인스턴스 dispose는 필요시 사용
      return;
    }

    setState(() {
      isLoading = false;
    });

    if (question != null) {
      // 다이얼로그를 보여주는 코드는 기존과 동일하게 작동합니다.
      // ... (기존 다이얼로그 코드) ...
       final correctOption = question['Correct_Option'] != null
            ? int.tryParse(question['Correct_Option'].toString())
            : null;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white,
          title: Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blue),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$date - Question $questionId',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question['Big_Question'] != null &&
                    question['Big_Question'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildContent(
                      question['Big_Question'],
                      context,
                      isBold: true,
                    ),
                  ),
                if (question['Question'] != null &&
                    question['Question'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContent(
                      question['Question'],
                      context,
                    ),
                  ),
                if (question['Image'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContent(
                      question['Image'],
                      context,
                      isImage: true,
                    ),
                  ),
                ...List.generate(4, (index) {
                  final optionKey = 'Option${index + 1}';
                  final optionData = question[optionKey];
                  if (optionData == null ||
                      (optionData is String && optionData.isEmpty)) {
                    return SizedBox.shrink();
                  }
                  final isCorrect = correctOption == index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${['➀', '➁', '➂', '➃'][index]} ',
                          style: TextStyle(
                            fontSize: 16,
                            color: isCorrect
                                ? Colors.blue
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black),
                            fontWeight: isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Expanded(
                          child: _buildContent(
                            optionData,
                            context,
                            isCorrect: isCorrect,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]
                      : Colors.grey[300],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '정답 설명',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue
                          : Colors.blue[700],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    question['Answer_description']?.toString() ?? '설명 없음',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '닫기',
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('question$examSession.db에서 Question_id $questionId에 해당하는 문제를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // 데이터베이스 인스턴스는 앱 전체에서 관리되므로 여기서 개별적으로 닫지 않는 것이 좋습니다.
    // DatabaseHelper.disposeInstance(dbPath); 
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('문제 데이터를 로드하는 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Widget _buildContent(dynamic data, BuildContext context,
      {bool isBold = false, bool isCorrect = false, bool isImage = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Uint8List? imageBytes;

    try {
      if (data is Uint8List) {
        imageBytes = data;
      } else if (data is List<dynamic>) {
        try {
          imageBytes = Uint8List.fromList(data.cast<int>());
        } catch (e) {
          // 변환 실패 시 아무것도 하지 않음
        }
      }
    } catch (e) {
      // 데이터 변환 중 오류 발생 시 아무것도 하지 않음
    }

    if (imageBytes != null && imageBytes.length > 100) {
      bool isValidImage = false;
      if (imageBytes.length > 4) {
        if (imageBytes[0] == 0xFF &&
            imageBytes[1] == 0xD8 &&
            imageBytes[2] == 0xFF) {
          // JPEG
          isValidImage = true;
        } else if (imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47) {
          // PNG
          isValidImage = true;
        } else if (imageBytes[0] == 0x47 &&
            imageBytes[1] == 0x49 &&
            imageBytes[2] == 0x46) {
          // GIF
          isValidImage = true;
        }
      }

      if (isValidImage) {
        return Container(
          constraints: BoxConstraints(maxWidth: 280, maxHeight: 400),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text('이미지를 표시할 수 없습니다.',
                  style: TextStyle(color: Colors.red, fontSize: 14));
            },
          ),
        );
      } else {
        return Text('[이미지 데이터 - 표시할 수 없음]',
            style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey : Colors.grey[700]));
      }
    } else {
      String text = data?.toString() ?? '';
      if (text.length > 100 && RegExp(r'^\d+$').hasMatch(text)) {
        return Text('[이미지 데이터로 추정됨]',
            style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey : Colors.grey[700]));
      }
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isCorrect
              ? Colors.blue
              : (isDarkMode ? Colors.white : Colors.black),
          fontWeight: isBold
              ? FontWeight.bold
              : (isCorrect ? FontWeight.bold : FontWeight.normal),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '비법노트',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF3A4A68) : Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              if (!mounted) return; // 네비게이션 전 mounted 확인
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Color(0xFF1C1C28) : Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 테스트 모드 표시 배너 추가
            if (_isTestMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: Colors.orange.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '테스트 모드: 10초 자동 정지',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            // 오디오 플레이어 UI - 항상 표시
            Container(
              color: isDarkMode ? Color(0xFF252535) : Colors.grey[100],
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 타이틀
                  Text(
                    "강의 듣기",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  // 오디오 상태에 따른 UI 표시
                  if (_isAudioLoading)
                    // 로딩 중
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.blue[300]! : Colors.blue,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '오디오를 준비하고 있습니다...',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else if (_errorMessage.isNotEmpty)
                    // 오류 발생
                    Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = '';
                              _isAudioLoading = true;
                            });
                            _initAudioPlayer();
                          },
                          child: Text('다시 시도'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    // 정상 오디오 플레이어 UI
                    Column(
                      children: [
                        // 재생/일시정지 버튼
                        ElevatedButton(
                          onPressed: _isAudioInitialized ? _playPause : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.blueGrey[700]
                                : Color(0xFF4A90E2),
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isPlaying ? '일시정지' : '강의 재생',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // 컨트롤
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '재생 속도: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                ),
                                DropdownButton<double>(
                                  value: _currentSpeed,
                                  isDense: true,
                                  underline: Container(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                  dropdownColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  onChanged: _isAudioInitialized
                                      ? (double? newValue) {
                                          if (newValue != null) {
                                            _changePlaybackSpeed(newValue);
                                          }
                                        }
                                      : null,
                                  items: _speedOptions
                                      .map<DropdownMenuItem<double>>(
                                          (double value) {
                                    return DropdownMenuItem<double>(
                                      value: value,
                                      child: Text(
                                        '${value}x',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            Text(
                              '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // 슬라이더
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                isDarkMode ? Colors.blue[300] : Colors.blue,
                            inactiveTrackColor: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            thumbColor:
                                isDarkMode ? Colors.blue[300] : Colors.blue,
                            overlayColor: isDarkMode
                                ? Colors.blue.withAlpha(32)
                                : Colors.blue.withAlpha(32),
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape:
                                RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble() > 0
                                ? _duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: _isAudioInitialized
                                ? (value) async {
                                    if (!mounted) return; // seek 전 mounted 확인
                                    await _audioPlayer
                                        .seek(Duration(seconds: value.toInt()));
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 노트 내용
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: studyNotes.entries.map((mainTopicEntry) {
                        final mainTopic = mainTopicEntry.key;
                        final mainValue = mainTopicEntry.value;
                        final mainDesc = mainValue['description'] as String;
                        List<Map<String, dynamic>> relatedQuestions = [];
                        if (mainValue.containsKey('related_questions') &&
                            mainValue['related_questions'] != null) {
                          final rawQuestions =
                              mainValue['related_questions'] as List<dynamic>;
                          if (rawQuestions.isNotEmpty) {
                            relatedQuestions = rawQuestions
                                .map((q) => q as Map<String, dynamic>)
                                .toList();
                          }
                        }
                        return Card(
                          margin: EdgeInsets.only(bottom: 24),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: isDarkMode ? Color(0xFF2A2A3C) : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _getTopicColor(mainTopic),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mainTopic.split('.').first,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        mainTopic.split('. ').last,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 24,
                                    color: isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    mainDesc,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                                if (relatedQuestions.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Color(0xFF22222E)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.play_circle_fill,
                                              size: 16,
                                              color: isDarkMode
                                                  ? Colors.blue[300]
                                                  : Colors.blue[700],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '관련 문제',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8.0,
                                          runSpacing: 8.0,
                                          children:
                                              relatedQuestions.map((question) {
                                            final date = question['date'];
                                            final questionId =
                                                question['question_id'];
                                            final shortDate = date
                                                .toString()
                                                .replaceAll('년 ', '.')
                                                .replaceAll('월', '');
                                            return InkWell(
                                              onTap: () => _showQuestionDialog(
                                                  context, date, questionId),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.blueGrey[800]
                                                      : Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '$shortDate (#$questionId)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDarkMode
                                                        ? Colors.blue[200]
                                                        : Colors.blue[700],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTopicColor(String topic) {
    int topicNumber = int.tryParse(topic.split('.').first) ?? 0;
    switch (topicNumber) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.pink;
      case 6:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}

class BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  BytesAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start = start ?? 0;
    end = end ?? _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
