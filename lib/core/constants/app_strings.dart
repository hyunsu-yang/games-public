/// UI strings for SnapPuzzle (Korean + English).
///
/// Korean is the primary language; English keys are provided for reference.
abstract final class AppStrings {
  // App name
  static const String appName = 'SnapPuzzle';
  static const String appTagline = '찍은 사진이 퍼즐이 되는 마법';

  // Home screen
  static const String homeTitle = '스냅퍼즐';
  static const String homeCameraButton = '사진 찍고 퍼즐 만들기!';
  static const String homeAlbumButton = '나의 퍼즐 앨범';
  static const String homeSettings = '설정';

  // Camera / gallery
  static const String cameraTitle = '사진 찍기';
  static const String galleryButton = '갤러리에서 선택';
  static const String cameraButton = '카메라로 찍기';
  static const String retake = '다시 찍기';
  static const String usePhoto = '이 사진 사용하기';
  static const String cropGuide = '퍼즐로 만들 영역을 선택하세요';

  // Puzzle mode selection
  static const String choosePuzzle = '어떤 퍼즐로 만들까요?';
  static const String jigsawMode = '직소 퍼즐';
  static const String slideMode = '슬라이드 퍼즐';
  static const String rotateMode = '회전 퍼즐';
  static const String spotMode = '틀린그림 찾기';
  static const String jigsawDesc = '조각을 맞춰보세요!';
  static const String slideDesc = '밀어서 완성해요!';
  static const String rotateDesc = '돌려서 맞춰요!';
  static const String spotDesc = '다른 부분을 찾아요!';

  // Difficulty
  static const String chooseDifficulty = '난이도를 선택하세요';
  static const String easy = '쉽게 ★';
  static const String medium = '보통 ★★';
  static const String hard = '어려워 ★★★';
  static const String easyDesc = '6조각 / 힌트 있음';
  static const String mediumDesc = '12조각 / 외곽선';
  static const String hardDesc = '20조각 / 힌트 없음';

  // Gameplay
  static const String hint = '힌트';
  static const String moves = '이동';
  static const String time = '시간';
  static const String pause = '잠깐!';
  static const String resume = '계속하기';
  static const String restart = '다시 시작';
  static const String quit = '그만하기';
  static const String tilesLeft = '남은 타일';

  // Completion
  static const String congratulations = '완성했어요! 🎉';
  static const String puzzleComplete = '퍼즐을 다 맞췄어요!';
  static const String yourStars = '받은 별';
  static const String bestTime = '최고 기록';
  static const String playAgain = '한 번 더!';
  static const String newPuzzle = '새 퍼즐 만들기';
  static const String backHome = '홈으로';

  // Collection / Album
  static const String albumTitle = '나의 퍼즐 앨범';
  static const String albumEmpty = '아직 완성한 퍼즐이 없어요.\n사진을 찍어 첫 퍼즐을 만들어요!';
  static const String allModesBadge = '모든 퍼즐 완성!';
  static const String totalStars = '총 별';
  static const String level = '레벨';
  static const String levelBeginner = '퍼즐 초보자';
  static const String levelIntermediate = '퍼즐 친구';
  static const String levelAdvanced = '퍼즐 고수';
  static const String levelMaster = '퍼즐 마스터';

  // Parental controls
  static const String parentalTitle = '보호자 설정';
  static const String parentalUnlock = '보호자 확인';
  static const String parentalPin = 'PIN 번호 입력';
  static const String parentalMathQuestion = '문제를 풀어 잠금 해제';
  static const String timeLimit = '플레이 시간 제한';
  static const String timeLimitNone = '무제한';
  static const String timeLimitHalf = '30분';
  static const String timeLimitOne = '1시간';
  static const String cameraAccess = '카메라 허용';
  static const String saveToGallery = '갤러리에 사진 저장';
  static const String statistics = '오늘의 통계';
  static const String todayPlayTime = '오늘 플레이 시간';
  static const String todayPuzzles = '오늘 완성한 퍼즐';
  static const String favoritePuzzle = '좋아하는 퍼즐';

  // Permissions
  static const String cameraPermissionTitle = '카메라 권한이 필요해요';
  static const String cameraPermissionMsg =
      '사진을 찍어 퍼즐을 만들려면 카메라 권한이 필요해요. 갤러리에서 사진을 선택하거나 설정에서 권한을 허용해주세요.';
  static const String galleryPermission = '갤러리 선택으로 하기';
  static const String openSettings = '설정 열기';

  // Errors
  static const String errorGeneral = '오류가 생겼어요. 다시 시도해 주세요.';
  static const String errorImageLoad = '사진을 불러오지 못했어요.';
  static const String errorPuzzleGenerate = '퍼즐을 만드는 중 오류가 생겼어요.';

  // Spot-the-difference
  static const String spotFound = '찾았어요!';
  static const String spotRemaining = '남은 차이';
  static const String timeUp = '시간 초과!';

  // Rotate
  static const String tapToRotate = '탭하면 돌아가요!';
  static const String allCorrect = '모두 맞췄어요!';
}
