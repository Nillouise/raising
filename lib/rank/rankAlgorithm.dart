import 'dart:math';

double getScore(DateTime currentTime, int readSecond, double cooling, double shrinkageFactor) {
  Duration difference = currentTime.difference(DateTime(2020));
  if (readSecond < 10) {
    return 0.1 * log(readSecond) / log(10) * exp(cooling * difference.inDays - shrinkageFactor);
  }
  return log(readSecond) / log(10) * exp(cooling * difference.inDays - shrinkageFactor);
}

//14天后，分值变大为3.2倍
double getShorttermScore(int readSecond, double shrinkageFactor) {
  return getScore(DateTime.now(), readSecond, 0.085, shrinkageFactor);
}

//60天后，分值变大为3.2倍
double getLongtermScore(int readSecond, double shrinkageFactor) {
  return getScore(DateTime.now(), readSecond, 0.02, shrinkageFactor);
}
