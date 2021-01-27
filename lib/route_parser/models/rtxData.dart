class TourData {
  double totalDistance;
  double uphill;
  double downhill;
  double maximumHeight;
  double minimumHeight;
  double travelTimeAverage10;
  double travelTimeAverage20;
}

class TourEvaluation {
  Map difficulty;
  double overallDifficulty;
  double uphillDifficulty;
  double downhillDifficulty;

  Map physicalCondition;
  double overallCondition;
  double totalHeightVariation;
  double totalDistance;
  double maximumAltitude;

  Map ridingSkills;
  double overallRiding;
  double surface;
  double averageClimbGradient;
  double averageDescentGradient;

  Map emotionalExperience;
  double panorama;
  double fun;

  TourEvaluation(
      this.overallDifficulty,
      this.uphillDifficulty,
      this.downhillDifficulty,
      this.overallCondition,
      this.totalHeightVariation,
      this.totalDistance,
      this.maximumAltitude,
      this.overallRiding,
      this.surface,
      this.averageClimbGradient,
      this.averageDescentGradient,
      this.panorama,
      this.fun) {
    this.difficulty = {
      'overall': overallDifficulty,
      'uphill': uphillDifficulty,
      'downhill': downhillDifficulty
    };
    this.physicalCondition = {
      'overall': overallCondition,
      'totalHeightVariation': totalHeightVariation,
      'totalDistance': totalDistance,
      'maximumAltitude': maximumAltitude
    };
    this.ridingSkills = {
      'overall': overallRiding,
      'surface': surface,
      'averageClimbGradient': averageClimbGradient,
      'averageDescentGradient': averageDescentGradient
    };
    this.emotionalExperience = {
      'panorama': panorama,
      'fun': fun,
    };
  }
}
