#!/usr/bin/perl

use Math::Fraction qw(:DEFAULT :STR_NUM);

sub examples;
sub pevel;

$f1 = Math::Fraction->new(1,2);
$f2 = Math::Fraction->new(1,3);
$f3 = Math::Fraction->new(5,3,MIXED);
$f4 = Math::Fraction->new(1,3,NO_REDUCE);

print <<'---';

Fraction "Calculator" for testing the Fraction Module.

Simply enter in any valid perl expression.  The results are printed
to the screen and stored the variable $ans for referring back to.

Examples:
 >5+5
 10
 >$ans*2
 20
 >frac(1,2)
 1/2
 >$ans*frac(1,2)
 1/4

To see a demonstration of the fraction module features type in "demo".

---
print "Pre-Set: \$f1=$f1  \$f2=$f2  \$f3=$f3  \$f4=$f4(NO_REDUCE)\n";

print ">";
while(<>) {$ans = eval; print $@; print "$ans\n>";}

sub pevel {
  print ">$_[0]\n";
  $ans = eval $_[0];
  print " $ans\n";
}

sub evelp {
  print ">$_[0]\n";
  eval $_[0];
}

sub pause {
  print "Press Enter to go on\n";
  <STDIN>;
}

sub demo {
  local($f1,$f2);

  pevel q~frac(1, 3)~;
  pevel q~frac(4, 3, MIXED)~;
  pevel q~frac(1, 1, 3)~;
  pevel q~frac(1, 1, 3, MIXED)~;
  pevel q~frac(10)~;
  pevel q~frac(10, MIXED)~;
  pevel q~frac(.66667)~;
  pevel q~frac(1.33333, MIXED)~;
  pevel q~frac("5/6")~;
  pevel q~frac("1 2/3")~;
  pevel q~frac(10, 20, NO_REDUCE)~;
  pause;
  evelp q~$f1=frac(2,3); $f2=frac(4,5);~;
  pevel q~$f1 + $f2~;
  pevel q~$f1 * $f2~;
  pevel q~$f1 + 1.6667~;
  evelp q~$f2->modify_tag(MIXED)~;
  pevel q~$f2 + 10~;
  pevel q~frac($ans, NORMAL) # trick to create a new fraction with different tags~;  
  pevel q~$f1 + $f2          # Add two unlikes it goes to default mode~;
  pevel q~$f1**1.2~;
  pevel q~$f1->num**1.2~;
  pevel q~frac(1,2)+frac(2,5)~;
  pause;
  evelp q~$f1=frac(5,3,NORMAL); $f2=frac(7,5);~;
  pevel q~"$f1  $f2"~;
  evelp q~Math::Fraction->modify_tag(MIXED)~;
  pevel q~"$f1  $f2"~;
  pevel q~$f1 = frac("3267893629762/32678632179820", BIG)~;
  pevel q~$f2 = frac("5326875886785/76893467996910", BIG)~;
  pevel q~$f1+$f2~;
  pevel q~$f1*$f2~;
  pevel q~$f1->num~;
  evelp q~Math::Fraction->modify_digits(15)~;
  pevel q~$f1->num~;
  pause;
  Math::Fraction->modify_tag(NORMAL);
  Math::Fraction->modify_digits(undef);
  return undef;
}



