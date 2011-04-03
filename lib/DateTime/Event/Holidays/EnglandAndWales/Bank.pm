package DateTime::Event::Holidays::EnglandAndWales::Bank;

use warnings;
use strict;
use Carp;

use DateTime;
use DateTime::Span;
use DateTime::Format::DateManip;

use Date::Manip;

=head1 NAME

DateTime::Event::Holidays::EnglandAndWales::Bank - Perl DateTime extension for getting England and Wales bank holiday dates for any year

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

use DateTime;
use DateTime::Event::Holidays::EnglandAndWales::Bank;
 
 my $year = '2011'; 

 my $bank_holiday = DateTime::Event::Holidays::EnglandAndWales::Bank->new( year => $year );                  

    # These are DateTime objects of the date in the year of instantiation
    my $new_year_dt   = $bank_holiday->new_years_day();
    my $good_fri_dt   = $bank_holiday->good_friday();
    my $easter_m_dt   = $bank_holiday->easter_monday();
    my $early_may_dt  = $bank_holiday->early_may_bank_holiday();
    my $sprint_bh_dt  = $bank_holiday->spring_bank_holiday();
    my $august_bh_dt  = $bank_holiday->summer_bank_holiday();
    my $christmas_dt  = $bank_holiday->christmas_day();
    my $boxing_day_dt = $bank_holiday->boxing_day();
 
 
 my $dt = DateTime->new( year   => 2011,
                         month  => 12, # these don't actually matter
                         day    => 31, # is uses the year
                   );
 
 my $christmas_dt  = $bank_holiday->christmas_day( $dt );
 my $boxing_day_dt = $bank_holiday->boxing_day( $dt );
 # etc... returns DateTime objeccts of the date in the year passed in the $dt
 
 
 $dt = DateTime->new( 
        year   => 2010,
        month  => 12,
        day    => 28,
 );
 
 # tests if $dt is a bank holiday, if it is returns a string of the name
 my  $bank_holiday_name = $bank_holiday->is_a_bank_holiday( $dt );
 # boxing_day
 
 
 my $dt1 = DateTime->new( 
        year   => 2008,
        month  => 10,
        day    => 3,
 );
    
  my $dt2 = DateTime->new( 
        year   => 2008,
        month  => 10,
        day    => 10,
 );


 my $days_bh        = $bank_holiday->bank_holidays_between_dates( $dt1, $dt2 );
 my $working_days   = $bank_holiday->uk_working_days_between_dates( $dt1, $dt2 );
 


=head1 DESCRIPTION

This module is used to calculate bank holiday dates in England and Wales. It will also calculate the number of working days in a time span.
The definition of each of the bank holidays is taken from:
http://www.berr.gov.uk/whatwedo/employment/bank-public-holidays/index.html


=head1 METHODS

=head2 new
If instantiated without parameters its internal date will default to the 1st of January of the current year.

New constructor can take the parameter of 'year', the internal date will then be the 
1st of January of that year and methods will return dates pertaining to that year

=cut


sub new {
    my $class = shift;
    my $dt = DateTime->now;
    
    my %self;
    
    my %args = validate(
        @_, {
            year => { type => SCALAR, optional => 1 },
        }
    );
    
    
    if ( $args{ 'year'} ) {
    
        $self{ 'dt' } = DateTime->new( 
            year   => $args{ 'year' },
            month  => 1,
            day    => 1,
        );
    } 
    else {
        $self{ 'dt' } = DateTime->now;
        #ugly alert
        $self{ 'dt' } = _set_to_first_jan( undef, $self{ 'dt' } );
    }
    
    
    $self{ 'bank_holidays' } = [    
        'new_years_day',          'good_friday',         'easter_monday', 
        'early_may_bank_holiday', 'spring_bank_holiday', 'summer_bank_holiday',    
        'christmas_day',          'boxing_day'
    ];
    
    return bless \%self, $class;
    
}


=head2 uk_working_days_between_dates
This methods takes two DateTime objects (which must be one after the other) and then
returns the number of working days between the two dates and is inclusive of the 
dates passed in. A working day counts as Mon-Fri and non-bank holiday. 
=cut


sub uk_working_days_between_dates {
    # takes two DateTime objects and returns the number of working days in the UK between the two dates (and inclusive of the dates)
    my $self = shift;
    my $dt1  = shift || croak "DateTime object required for span start";
    my $dt2  = shift || croak "DateTime object required for span end";
    
    # I'm going to have two conditions of use here, you have to provide two $dt objects (done above) and $dt2 must be after $dt1
    if ( DateTime->compare( $dt1, $dt2 ) >= 0 ) {
        croak "DateTime object for end must be after DateTime object for start";
    }
    
    my $diff = $dt2 - $dt1;
    my $duration = $diff->delta_days;
    $duration++; # Because fo the way we calculate the duration it's not inclusive of the fist date so we just add one day.

    
    $duration = $duration - $self->bank_holidays_between_dates( $dt1, $dt2 );
    $duration = $duration - $self->_weekends_between_dates( $dt1, $dt2 );
    
    return $duration;
}



=head2 bank_holidays_between_dates
This method takes two DateTime objects (which must be one after the other) and then
returns the number of bank holidays between the two dates. This is includsive of the
dates passed in.
=cut

sub bank_holidays_between_dates {
    # takes two DateTime objects and returns the number of England and Wales bank holidays them (inclusive of the dates)
    my $self = shift;
    my $dt1  = shift || croak "DateTime object required for span start";
    my $dt2  = shift || croak "DateTime object required for span end";
    
    # I'm going to have two conditions of use here, you have to provide two $dt objects (done above) and $dt2 must be after $dt1
    if ( DateTime->compare( $dt1, $dt2 ) >= 0 ) {
        croak "DateTime object for end must be after DateTime object for start";
    }
    
    my $count_bh = 0;
    
    my $span = DateTime::Span->from_datetimes( start => $dt1, end => $dt2 );
    
    # we might have been provided a two dt objects that were not in our current or instantiation year so we'll record this and switch
    # $self->{ 'dt' } to be the start year
    my $instantiation_year = $self->{ 'dt' }->year;
    $self->{ 'dt' }->set( year => $dt1->year );   
    
    foreach my $bank_holiday ( @{ $self->{ 'bank_holidays' } } ) {
        if ( $span->contains( $self->$bank_holiday( $self->{ 'dt' } ) ) ) { 
            $count_bh++;
        }
    }
    
    # the foreach above counts the bank holidays in the year of instantiation of $self, however $span make be over a year or more
    # so we're going to check this and then iterate over the number of years and change the year of $self->{ 'dt' }
    if ( $dt1->year != $dt2->year ) {
        # so we know from above that $dt2 !< $dt1 so we can foreach from one to the other!
        foreach my $year ( ( $dt1->year + 1 ) .. $dt2->year ) {
            # now we set the year of $self->{ 'dt' } 
            $self->{ 'dt'}->set( year => $year );   
            #and now we can check for bankholidays : )
            foreach my $bank_holiday ( @{ $self->{ 'bank_holidays' } } ) {
                if ( $span->contains( $self->$bank_holiday( $self->{ 'dt' } ) ) ) { 
                    $count_bh++;
                }
            }
        }
    }
    
    #reset $self->{ 'dt' } to the instantiation years
    $self->{ 'dt' }->set( year => $instantiation_year );   
    
    return $count_bh;
}
    

=head2 is_a_bank_holiday
This method takes a DateTime object and performs a test to see if this is a bank 
holiday, if it is it will return a string of the bank holiday (these string are the
same as the method names), if it is not it returns a 0.

=cut

sub is_a_bank_holiday {
    # takes a DateTime object and then tests if this date is bank holiday, returns the name of the bank holiday
    my $self = shift;
    my $dt   = shift || croak "DateTime object required for comparison";
    
    my $cmp;
    foreach my $bank_holiday ( @{ $self->{ 'bank_holidays' } } ) {
        $cmp = DateTime->compare( $dt, $self->$bank_holiday( $self->{ 'dt' } ) );
        if ( !$cmp ) { return $bank_holiday; }
    }
    
    # if this hasn't returned in the loop above then it wasn't a bank holiday, return 0
    return 0;    
}

=head2 new_years_day
If a DateTime object is passed it takes its year and then returns a DateTime object of 
new years day bank holiday that year. If nothing is passed is uses its internal year.
=cut

sub new_years_day {
    # takes the year in a DateTime object and returns the a DateTime object of the new years day bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;

    $dt = $self->_set_to_first_jan( $dt );
    
    my $dm = DateTime::Format::DateManip->format_datetime( $dt );
    
    if ( $dt->day_of_week == 7 || $dt->day_of_week == 6 ) {
        #print "This appears to be a non-working day (or a Monday), searching for date of next working day\n";
        $dm =  Date_NextWorkDay( $dm );
    }
    
    my $dt_f_dm = DateTime::Format::DateManip->parse_datetime( $dm );

    return $dt_f_dm;    
}

=head2 good_friday
Easter calculations are done using DateTime::Event::Easter.
If a DateTime object is passed it takes its year and then returns a DateTime object of 
good friday bank holiday that year. If nothing is passed is uses its internal year.
=cut

sub good_friday {
    # takes the year in a DateTime object and returns the a DateTime object of the good friday bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;
    
    $dt = $self->_set_to_first_jan( $dt );
    
    my $easter_sunday = DateTime::Event::Easter->new();
  
    my $this_easter_sunday = $easter_sunday->following( $dt );
      
    return $this_easter_sunday->subtract( days => 2 );
    
}

=head2 easter_monday
Easter calculations are done using DateTime::Event::Easter.
If a DateTime object is passed it takes its year and then returns a DateTime object of 
good friday bank holiday that year. If nothing is passed is uses its internal year.

=cut

sub easter_monday {
    # takes the year in a DateTime object and returns the a DateTime object of the easter monday bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;
    
    $dt = $self->_set_to_first_jan( $dt );
    
    my $easter_sunday = DateTime::Event::Easter->new();
  
    my $this_easter_sunday = $easter_sunday->following( $dt );
      
    return $this_easter_sunday->add( days => 1 );
    
}

=head2 early_may_bank_holiday
This is the first Monday of May and works like the methods above regarding 
the year. Returns a DateTime object of the date of the bank holiday.

=cut

sub early_may_bank_holiday {
    # takes the year in a DateTime object and returns the a DateTime object of the early may bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;
    
    my $dm = ParseDate("1st Monday in May " . $dt->year );
    my $dt_f_dm = DateTime::Format::DateManip->parse_datetime( $dm );

    return $dt_f_dm;  
    
}


=head2 summer_bank_holiday
This is the last Monday of August and works like the methods above regarding 
the year. Returns a DateTime object of the date of the bank holiday.

=cut

sub summer_bank_holiday {
    # takes the year in a DateTime object and returns the a DateTime object of the summer bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;
    
    my $dm = ParseDate("Last Monday in August " . $dt->year );
    my $dt_f_dm = DateTime::Format::DateManip->parse_datetime( $dm );

    return $dt_f_dm;  
    
}

=head2 christmas_day
The internal DateTime object is set to the 25th, a check is performed to see if this
falls on a working day, in which case this is the bank holiday. If Christmas day is
on a Sunday, Boxing day will be its own bank holiday and Christmas bank holiday is 
carried to the Tuesday. If Christmas day is on a Saturday, its bank holiday is the 
following Monday. Returns a DateTime object of the date of the bank holiday.

=cut

sub christmas_day {
    # takes the year in a DateTime object and returns the a DateTime object of the christmas bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;

    $dt = $self->_set_to_25_dec( $dt );
    
    my $dm = DateTime::Format::DateManip->format_datetime( $dt );
    
    # There's a strange exception with christmas day, if it falls on a Sunday the bankholiday is actually on the following tuesday becuase the monday is a boxing day
    if ( $dt->day_of_week == 7 ) {
        $dm =  Date_NextWorkDay( $dm, 1 );
    }
    elsif ( $dt->day_of_week == 6 ) {
        $dm =  Date_NextWorkDay( $dm );
    }
    
    my $dt_f_dm = DateTime::Format::DateManip->parse_datetime( $dm );

    return $dt_f_dm;    
}


=head2 boxing_day
The internal DateTime object is set to the 26th, a check is performed to see if this 
falls on a working day, in which case this is the bank holiday. If it falls on a
Sunday the bank holiday will be the following Tuesday (Christmas bank holiday will
be the Monday). Returns a DateTime object of the date of the bank holiday.

=cut

sub boxing_day {
    # takes the year in a DateTime object and returns the a DateTime object of the boxing day bank holiday
    # if no year is passed is takes a default of the current year
    my $self = shift;
    my $dt   = shift || $self->{ 'dt' } ;

    $dt = $self->_set_to_25_dec( $dt );
    $dt->add( days => 1 );
     
    my $dm = DateTime::Format::DateManip->format_datetime( $dt );
    
    if ( $dt->day_of_week == 7 ) {
        # if boxing day is a sunday (therefore xmas is a saturday), xmas' holiday will be monday and boxing day's must be tuesday
        $dm =  Date_NextWorkDay( $dm, 1 );
    } 
    elsif ( $dt->day_of_week == 6 ) {
        # if the above isn't true then this must be a saturday
        # if boxing day is on a saturday then the next working day will do
        $dm =  Date_NextWorkDay( $dm );
    }
    # if boxing day is on a week day then it'll be the 26th
 
    
    my $dt_f_dm = DateTime::Format::DateManip->parse_datetime( $dm );

    return $dt_f_dm;    
}


# private methods.
sub _set_to_25_dec {
    my $self = shift;
    my $dt   = shift;
    
    $dt->set( day   => 25 );    
    $dt->set( month => 12 );    
    
    return $dt;
}
    
sub _set_to_first_jan {
    my $self = shift;
    my $dt   = shift;
    
    $dt->set( day   => 1 );    
    $dt->set( month => 1 );    
    
    return $dt;
}
 
sub _weekends_between_dates {
    # takes two DateTime objects and returns the number of weekend days in the UK between the two dates (and inclusive of the dates)
    my $self = shift;
    my $dt1  = shift || croak "DateTime object required for span start";
    my $dt2  = shift || croak "DateTime object required for span end";
    
    # I'm going to have two conditions of use here, you have to provide two $dt objects (done above) and $dt2 must be after $dt1
    if ( DateTime->compare( $dt1, $dt2 ) >= 0 ) {
        croak "DateTime object for end must be after DateTime object for start";
    }
    
    my $count_weekendend_days = 0;    
    
    for (my $dt_day = $dt1; DateTime->compare( $dt_day, $dt2 ) <= 0; $dt_day->add( days => 1) ) {
        if ( $dt_day->day_of_week == 6 || $dt_day->day_of_week == 7 ) {
            $count_weekendend_days++;
        }
    }
        
    return $count_weekendend_days;
}



=head1 AUTHOR

Kristian Flint, C<< <kristian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-event-holidays-englandandwales-bank at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Holidays-EnglandAndWales-Bank>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Holidays::EnglandAndWales::Bank


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Holidays-EnglandAndWales-Bank>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Holidays-EnglandAndWales-Bank>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Holidays-EnglandAndWales-Bank>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Holidays-EnglandAndWales-Bank/>

=back


=head1 ACKNOWLEDGEMENTS
Much help from the DateTime mailing list

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kristian Flint, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DateTime::Event::Holidays::EnglandAndWales::Bank
