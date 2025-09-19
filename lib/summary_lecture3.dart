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
  "1. 바 기물 및 글라스 관리·세척·보관": {
    'description':
        '''- 글라스 사용 전 가장자리(Rim) 칩·금부터 확인해 고객 안전 확보.
- 세척은 중성세제+더운물 세척 → 찬물 헹굼이 표준(살균·세제 잔류 최소화).
- 림→볼→스템→풋 순으로 닦아 오염 역전이 방지.
- 은·동 기물은 전용 세척액에 “짧게” 담가 즉시 헹궈 변색·부식을 예방.
- 크리스털·스템웨어는 전용 랙 또는 손 세척으로 파손 방지, 동종끼리 보관.
- 탄산음료·샴페인 잔량 보관 시 전용 스토퍼로 압력 유지, 청량감 보존.
- Soft-drink 디캔터·칵테일 디캔터는 ‘술과 분리된’ 청량음료·사이드 드링크 전용.
- Chaser(콜라·물 등)는 ‘음료’이지 기물이 아니므로 바 기물 목록에 포함되지 않음.
- Irish Coffee·핫 토디류는 내열 글라스를 사용, 급열‧급냉 충격 방지.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 32},
      {'date': '2016년 1월', 'question_id': 34},
      {'date': '2016년 1월', 'question_id': 40},
      {'date': '2016년 1월', 'question_id': 44},
      {'date': '2016년 1월', 'question_id': 46},
      {'date': '2016년 4월', 'question_id': 34},
      {'date': '2016년 4월', 'question_id': 37},
      {'date': '2016년 4월', 'question_id': 42},
      {'date': '2016년 7월', 'question_id': 44},
      {'date': '2016년 7월', 'question_id': 47},
      {'date': '2016년 7월', 'question_id': 48},
    ],
  },
  "2. 칵테일 제조 기법과 도구": {
    'description':
        '''- Shaking: 고밀도 재료·주스·계란·유제품 포함 시 사용, ‘바디→얼음→토픈→캡’ 순으로 조립.
- Stirring: 투명 증류주·비중 유사 재료 혼합 시 적용, Mixing Glass+Bar Spoon 사용.
- Floating/Layering: 비중 차를 이용해 층을 만드는 기법(Pousse Café, B-52 등).
- Blending: Crushed Ice와 재료를 블렌더로 초고속 혼합, 슬러시 질감 생성.
- Build(직접조주): 글라스에 재료를 차례로 붓는 가장 단순한 방법(Black Russian 등).
- 계량 도구(Jigger) 사용은 맛 표준화·원가 관리의 기본, 미사용은 바텐더 직무 위반.
- 아이스 타입 선택: Shake/Stir → 큐브아이스, Blend → Crushed Ice가 적합.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 37},
      {'date': '2016년 1월', 'question_id': 49},
      {'date': '2016년 4월', 'question_id': 38},
      {'date': '2016년 4월', 'question_id': 39},
      {'date': '2016년 7월', 'question_id': 32},
      {'date': '2016년 7월', 'question_id': 33},
      {'date': '2016년 7월', 'question_id': 38},
      {'date': '2016년 7월', 'question_id': 41},
      {'date': '2016년 7월', 'question_id': 42},
    ],
  },
  "3. 가니시(Garnish)의 종류·손질·적용 원칙": {
    'description':
        '''- 목적: 시각미·향·맛 보완, 음료 아이덴티티 부여(올리브→마티니, 펄 오니언→Gibson).
- 재료: 과일 슬라이스·필, 허브 잎·줄기, 식용 꽃 등 ‘식용 가능’ 소재 사용.
- 손질 타이밍: 수분 많은 딸기 등은 주문 직전에, 레몬·오렌지는 미리 슬라이스 후 밀폐 보관.
- 칵테일별 매칭:
· Gin&Tonic – Lemon Slice / Old Fashioned – Orange+Cherry
· Manhattan·Rob Roy – Red Cherry / Gibson – Cocktail Onion
· Gimlet – 일반적으로 가니시 없음.
- 강한 향의 꽃·꽃가루 많은 재료는 음료 향을 해치거나 위생 문제 유발 → 사용 지양.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 45},
      {'date': '2016년 4월', 'question_id': 43},
      {'date': '2016년 4월', 'question_id': 44},
      {'date': '2016년 4월', 'question_id': 48},
      {'date': '2016년 4월', 'question_id': 50},
      {'date': '2016년 7월', 'question_id': 34},
      {'date': '2016년 7월', 'question_id': 35},
    ],
  },
  "4. 칵테일 레시피와 베이스 주류 판별": {
    'description':
        '''- 베이스 스피릿별 대표 칵테일
· Rum: Daiquiri, Cuba Libre, Mai-Tai (Stinger는 Brandy 베이스)
· Vodka: Screwdriver, Bloody Mary, Black Russian (Margarita는 Tequila)
· Whisky: Manhattan, Rob Roy, New York (Black Russian은 Whisky 無)
- 특수 재료 사용 예
· Egg: Brandy Eggnog, Millionaire 등 – 영양·풍미 강화, 위생 관리 필수.
· Bitters: Manhattan, Old Fashioned, Negroni – 밸런스 조정 / Cosmopolitan에는 미사용.
- 층(색) 변화 고려: Kir Royal(Champagne+Crème de Cassis), Pousse Café(다층) 등.
- 칼로리·영양: 리큐어가 당분 첨가로 oz당 열량 최고, Eggnog류가 영양 밀도 최고.
- 레시피로는 색상·성분·분량 파악 가능하나 ‘판매량’은 알 수 없음.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 38},
      {'date': '2016년 1월', 'question_id': 43},
      {'date': '2016년 4월', 'question_id': 38},
      {'date': '2016년 4월', 'question_id': 45},
      {'date': '2016년 4월', 'question_id': 46},
      {'date': '2016년 4월', 'question_id': 47},
      {'date': '2016년 7월', 'question_id': 37},
      {'date': '2016년 7월', 'question_id': 40},
      {'date': '2016년 7월', 'question_id': 49},
      {'date': '2016년 7월', 'question_id': 50},
    ],
  },
  "5. 바 서비스 절차 및 고객 응대": {
    'description':
        '''- 추가 주문은 잔이 비기 前 여쭈어 공백 없는 서비스 흐름 유지.
- 칵테일 제공 순서: 냅킨 → 스터러 → 음료 글라스 순으로 고객 우측에 세팅.
- 샴페인 서비스: ① 잔 1/3만 1차로 따르고 거품 안정 후 ② 최대 ½까지 보충, 기포는 적당히 살려 시각적 가치 제공.
- Soft Drink Decanter: 탄산음료만 분리 제공, 술과 미리 혼합·얼음 첨가는 탄산 손실·희석 유발.
- Corkage: 외부 반입 와인에 부과되는 글라스 사용·서비스료. 마개 형태(코르크·스크루캡)와 무관.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 32},
      {'date': '2016년 1월', 'question_id': 35},
      {'date': '2016년 4월', 'question_id': 31},
      {'date': '2016년 4월', 'question_id': 32},
      {'date': '2016년 7월', 'question_id': 43},
    ],
  },
  "6. 바 유형 및 분위기 특징": {
    'description':
        '''- Classic Bar: 은은한 조명·차분한 음악, 정확한 계량·정통 서비스, 플레어(병 돌리기) 지양.
- Flare Bar: 화려한 퍼포먼스 중심, 젊고 역동적 분위기.
- Pub/Member’s Club Bar: 사교·맥주 중심, 캐주얼 또는 회원제 특성.
- Snack Bar는 간단 식·간식 제공 ‘일반음식점’으로 주류 중심 바 분류와 다름.
- Western Bar(미국식 살룬)는 밝고 활기차며 소란스러운 환경 → 클래식·조용한 바의 이미지와 대비.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 31},
      {'date': '2016년 7월', 'question_id': 36},
      {'date': '2016년 7월', 'question_id': 39},
    ],
  },
  "7. 조직 및 직무 역할": {
    'description':
        '''- 구매부: 원·식자재 구입 후 검수→저장→불출까지 담당, ‘판매’ 기능은 영업부 소관.
- 소믈리에: 와인 리스트 작성·추천·서비스·판매(=Wine Steward) 전담.
- 웨이터/웨이트리스: 주문 정확히 접수, 조주된 음료를 신속·안전하게 제공.
- 바텐더: 주류 재고 확인, 위생 관리, 표준 레시피 준수(지거 계량 필수).''',
    'related_questions': [
      {'date': '2016년 4월', 'question_id': 35},
      {'date': '2016년 4월', 'question_id': 36},
      {'date': '2016년 7월', 'question_id': 31},
      {'date': '2016년 7월', 'question_id': 45},
    ],
  },
  "8. 매출·원가·경영 지표": {
    'description':
        '''- 객단가 = 총매출액 ÷ 고객 수 → 개인당 평균 구매액.
- 인건비율 = 인건비 ÷ 매출액 × 100; 바의 적정 목표는 통상 25~35% 범위.
- 목표 판매가 산정: 판매가 = 원가 ÷ 목표 원가율(%) 예) 원가 10만 원, 원가율 20% → 병가 50만 원.
- 병당 잔 수(750 mL ÷ 30 mL ≈ 25잔)로 잔당 판매가 재분배.
- 레시피는 경영 지표(판매량·매출)를 제공하지 않으므로 POS·매출 집계가 별도로 필요.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 47},
      {'date': '2016년 4월', 'question_id': 41},
      {'date': '2016년 4월', 'question_id': 49},
      {'date': '2016년 7월', 'question_id': 46},
    ],
  },
  "9. 주류·음료 보관·숙성 및 탄산 유지": {
    'description':
        '''- 증류주 오크 숙성: 색·향·풍미 변화, ‘엔젤스 셰어’ 증발 발생 → 원액 그대로 유지되지 않음.
- 맥주: 4–10 ℃ 냉암소 보관, 직사광선·동결 금지, 장기 저장 시 품질 저하.
- Bock Beer: 고도수 짙은 라거, 신선도 관리에도 높은 도수 특성 고려.
- 와인·브랜디류(코냑·칼바도스): 15–20 ℃ 상온 셀러, 온도·빛 변동 최소화.
- 병 탄산음료·샴페인 보관: 전용 스토퍼로 밀봉, 미사용 시 탄산 손실 가속.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 36},
      {'date': '2016년 1월', 'question_id': 39},
      {'date': '2016년 1월', 'question_id': 40},
      {'date': '2016년 1월', 'question_id': 41},
      {'date': '2016년 1월', 'question_id': 42},
    ],
  },
  "10. 주류 관련 세금·부가 비용": {
    'description':
        '''- 개별소비세: 요정·카바레·나이트클럽 등 유흥접객업에 부과, ‘단란주점’은 과세 제외.
- Corkage(코키지): 외부 반입 와인에 부과되는 서비스·글라스 사용료, 코르크·스크루캡 구분 없음.
- 서비스료·세금은 메뉴판·와인 리스트에 사전 고지하여 결제 혼선을 예방.''',
    'related_questions': [
      {'date': '2016년 1월', 'question_id': 33},
      {'date': '2016년 7월', 'question_id': 43},
    ],
  },
};

class SummaryLecture3Page extends StatefulWidget {
  final String dbPath;

  SummaryLecture3Page({required this.dbPath});

  @override
  _SummaryLecture3PageState createState() => _SummaryLecture3PageState();
}

class _SummaryLecture3PageState extends State<SummaryLecture3Page>
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
    print('SummaryLecture3Page: Test mode enabled: $_isTestMode');

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
        'SummaryLecture3Page: Starting test mode timer: ${_testModeDuration.inSeconds} seconds');
    _testModeTimer = Timer(_testModeDuration, () {
      print('SummaryLecture3Page: Test mode timer expired - stopping audio');
      if (mounted && _isPlaying) {
        _audioPlayer.pause();
      }
    });
  }

  // 테스트 모드 타이머 취소
  void _cancelTestModeTimer() {
    if (_testModeTimer != null) {
      print('SummaryLecture3Page: Cancelling test mode timer');
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
          AudioSource.asset('audio/summary/lecture3.mp3'),
          preload: true,
        );
        print('DEBUG: AssetSource 오디오 로딩 성공');
      } catch (assetError) {
        print('DEBUG: AssetSource 실패: $assetError');

        // 방법 2: 다른 경로로 시도
        try {
          print('DEBUG: 전체 경로로 AssetSource 시도');
          await _audioPlayer.setAudioSource(
            AudioSource.asset('assets/audio/summary/lecture3.mp3'),
            preload: true,
          );
          print('DEBUG: 전체 경로 AssetSource 성공');
        } catch (fullPathError) {
          print('DEBUG: 전체 경로도 실패: $fullPathError');

          // 방법 3: BytesAudioSource (마지막 수단)
          try {
            print('DEBUG: BytesAudioSource로 fallback 시도');
            final ByteData data =
                await rootBundle.load('assets/audio/summary/lecture3.mp3');
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
        await rootBundle.load('assets/audio/summary/lecture3.mp3');
    final Uint8List bytes = data.buffer.asUint8List();

    // 임시 디렉토리에 파일 저장
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File('${tempDir.path}/temp_lecture3.mp3');
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
