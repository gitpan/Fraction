#!/usr/bin/perl

# Math::Fraction v.4a (24 March 1997) Test Script

use Math::Fraction qw(:DEFAULT :STR_NUM);
use Math::BigInt;
use Math::BigFloat;

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

$a = frac(5);

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
  Math::Fraction->load_set(DEFAULT);
}

sub s {
  my @ret = map {$_ eq undef() ? 'undef' : $_} @_;
  "@ret";
}

sub demo {
  local($f1,$f2);

  my $set = Math::Fraction->temp_set;

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
  pevel q~$f1 = frac("3267893629762/32678632179820")~;
  pevel q~$f2 = frac("5326875886785/76893467996910")~;
  pevel q~$f1->is_tag(BIG).",".$f2->is_tag(BIG) # Notice how neither of them is BIG ~;
  pevel q~$f1+$f2~;
  pevel q~$ans->is_tag(BIG)                     # But this answer is.~;
  pevel q~$f1*$f2~;
  pevel q~$ans->is_tag(BIG)                     # And so is this one.~;
  pause;
  pevel q~$f1 = frac("3267893629762/32678632179820", BIG)~;
  pevel q~$f1->is_tag(BIG)   # Notice how the big tag had no effect.~;
  evelp q~$f1->modify_tag(NO_AUTO, BIG)~;
  pevel q~$f1->is_tag(BIG)   # But now it does.  You have to turn off AUTO.~;
  pevel q~$f1->num~;
  evelp q~Math::Fraction->modify_digits(15)~;
  pevel q~$f1->num~;
  pevel q~$f1 = frac("0.123123123456456456456456456456123456789123456789123457")~;
  evelp q~Math::Fraction->modify_digits(75)~;
  pevel q~$f1->num~;
  pause;
  evelp q~$f1 = frac(7,5);~;
  evelp q~$f2 = frac("3267893629762/32678632179820", NO_AUTO, BIG)~;
  evelp q~Math::Fraction->modify_tag(MIXED); Math::Fraction->modify_digits(65)~;
  pevel q~"$f1 ".$f2->num~;
  evelp q~Math::Fraction->load_set(DEFAULT)~;
  pevel q~"$f1 ".$f2->num~;
  evelp q~Math::Fraction->modify_digits(25)~;
  pevel q~"$f1 ".$f2->num~;
  evelp q~$s = Math::Fraction->temp_set~;
  evelp q~Math::Fraction->modify_tag(MIXED); Math::Fraction->modify_digits(15)~;
  pevel q~"$f1 ".$f2->num~;
  evelp q~Math::Fraction->temp_set($s)~;
  pevel q~Math::Fraction->exists_set($s)~;
  pevel q~"$f1 ".$f2->num  # Notice how it goes back to the previous settings.~;
  pause;
  evelp q~Math::Fraction->name_set('temp1')~;
  evelp q~Math::Fraction->modify_tag(MIXED, NO_AUTO)~;
  evelp q~Math::Fraction->modify_digits(60)~;
  pevel q~&s(Math::Fraction->tags, Math::Fraction->digits)~;
  evelp q~Math::Fraction->save_set  # If no name is given it will be saved via~;
  evelp q~                          # its given name~;
  evelp q~Math::Fraction->load_set(DEFAULT)~;
  pevel q~&s(Math::Fraction->tags, Math::Fraction->digits)~;
  pevel q~&s(Math::Fraction->tags('temp1'), Math::Fraction->digits('temp1'))~;
  evelp q~  # ^^ Notice how this lets you preview other sets with out loading them.~;
  evelp q~Math::Fraction->load_set(DEFAULT)~;
  evelp q~Math::Fraction->use_set('temp1')~;
  evelp q~Math::Fraction->modify_tag(NO_REDUCE)~;
  pevel q~&s(Math::Fraction->tags, Math::Fraction->digits)~;
  pevel q~&s(Math::Fraction->tags('temp1'), Math::Fraction->digits('temp1'))~;
  evelp q~  # ^^ Notice how this also modifies the temp1 tag becuase it is being used~;
  evelp q~  #    if it was just loaded it would not do this becuase there is no link.~;
  pause;

  Math::Fraction->del_set('temp1');
  Math::Fraction->temp_set($set);

  return undef;
}



