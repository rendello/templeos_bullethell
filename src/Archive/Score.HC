
#define SCORE_NUM 30


I64 RandRangeI64(I64 min=0, I64 max) {
  // Fast biased integer multiplication method.
  // Described here:
  // $AN,"Efficiently Generating a Number in a Range",A="",HTML="http://www.pcg-random.org/posts/bounded-rands.html"$ (web link)

  return ((RandU32()(U64) * (max-min)) >> 32) + min;
}

class Score {
  I64 match_time;
  CDate date;
  Bool current_match;
};

I64 i;



Score scores[SCORE_NUM];
for (i=0;i<SCORE_NUM;i++) {
  scores[i].match_time = RandRangeI64(,i);
  scores[i].date = Now;
  scores[i].current_match = 0;

}

I64 ScoreCompare(Score *s1, Score *s2) {
  // For QSort.

  if (s1->match_time < s2->match_time)
    return 1;
  else if (s1->match_time == s2->match_time)
    return 0;
  else
    return -1;
}

QSort(scores,SCORE_NUM,sizeof(Score),&ScoreCompare);


for (i=0;i<SCORE_NUM;i++) {
  Print("%d\n",scores[i].match_time);
}

/*

I64 MoveCmp(Move *e1,Move *e2)
{
  if (e1->score<e2->score)
    return 1;
  else if (e1->score==e2->score)
    return 0;
  else
    return -1;
}

QSort(ptr2,cnt,sizeof(Move),&MoveCmp);
*/