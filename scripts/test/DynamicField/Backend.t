# --
# Backend.t - DynamicFieldValue backend tests
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id: Backend.t,v 1.4 2011-08-27 17:37:25 cr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.
# --

use strict;
use warnings;
use utf8;
use vars (qw($Self));

use Kernel::System::DynamicField;
use Kernel::System::DynamicField::Backend;
use Kernel::System::UnitTest::Helper;
use Kernel::System::Ticket;

my $HelperObject = Kernel::System::UnitTest::Helper->new(
    %$Self,
    UnitTestObject => $Self,
);

my $RandomID = int rand 1_000_000_000;

my $DynamicFieldObject = Kernel::System::DynamicField->new( %{$Self} );
my $BackendObject      = Kernel::System::DynamicField::Backend->new( %{$Self} );
my $TicketObject       = Kernel::System::Ticket->new( %{$Self} );

# create a ticket
my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Some Ticket Title',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerID   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

# sanity check
$Self->True(
    $TicketID,
    "TicketCreate() successful for Ticket ID $TicketID",
);

# create a dynamic field
my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
    Name       => "dynamicfieldtest$RandomID",
    Label      => 'a description',
    FieldOrder => 9991,
    FieldType  => 'Text',     # mandatory, selects the DF backend to use for this field
    ObjectType => 'Ticket',
    Config     => {
        DefaultValue => 'a value',
    },
    ValidID => 1,
    UserID  => 1,
);

# sanity check
$Self->True(
    $FieldID,
    "DynamicFieldAdd() successful for Field ID $FieldID",
);

my @Tests = (
    {
        Name     => 'No DynamicFieldConfig',
        ObjectID => $TicketID,
        UserID   => 1,
        Success  => 0,
    },
    {
        Name               => 'No ObjectID',
        DynamicFieldConfig => {
            ID         => -1,
            ObjectType => 'Ticket',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Invalid DynamicFieldConfig',
        DynamicFieldConfig => {},
        ObjectID           => $TicketID,
        UserID             => 1,
        Success            => 0,
    },
    {
        Name               => 'No ID',
        DynamicFieldConfig => {
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        UserID   => 1,
        Success  => 0,
    },
    {
        Name               => 'No ObjectType',
        DynamicFieldConfig => {
            ID => $FieldID,
        },
        ObjectID => $TicketID,
        UserID   => 1,
        Success  => 0,
    },
    {
        Name               => 'No UserID',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Success  => 0,
    },
    {
        Name               => 'Invalid Date',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueDateTime => '23-2003-12 - 45:90:80',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Invalid Date - No Time',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueDateTime => '1977-12-12',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Invalid Date - Just Time',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueDateTime => '12:00:00',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Invalid Integer - Letter',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueInt => 'a',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Invalid Integer - Numbers and Letters',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueInt => '123a',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Invalid Integer - Real Number',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueInt => '123.0',
        },
        UserID  => 1,
        Success => 0,
    },
    {
        Name               => 'Set Text Value',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueText => 'a text',
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set Text Value - empty',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueText => '',
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set Text Value - unicode',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueText => 'äöüßÄÖÜ€ис',
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set Date Value',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueDateTime => '1977-12-12 12:00:00',
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set Int Value',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueInt => 14524,
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set Int Value - Zero',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueInt => 0,
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set Int Value - Negative',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueInt => -10,
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set All Values',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueText     => 'a text',
            ValueDateTime => '1977-12-12 12:00:00',
            ValueInt      => 1,
        },
        UserID  => 1,
        Success => 1,
    },
    {
        Name               => 'Set All Values unicode',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        Value    => {
            ValueText     => 'äöüßÄÖÜ€ис',
            ValueDateTime => '1977-12-12 12:00:00',
            ValueInt      => 1,
        },
        UserID  => 1,
        Success => 1,
    },
);

for my $Test (@Tests) {
    my $Success = $BackendObject->ValueSet(
        DynamicFieldConfig => $Test->{DynamicFieldConfig},
        ObjectID           => $Test->{ObjectID},
        UserID             => $Test->{UserID},
        %{ $Test->{Value} },
    );

    if ( !$Test->{Success} ) {
        $Self->False(
            $Success,
            "ValueSet() - Test ($Test->{Name}) - with False",
        );

        # Try to get the value with ValueGet()
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $Test->{DynamicFieldConfig},
            ObjectID           => $Test->{ObjectID},
        );

        $Self->False(
            $Value->{ID},
            "ValueGet() - Test ($Test->{Name}) - with False",
        );

    }
    else {
        $Self->True(
            $Success,
            "ValueSet() - Test ($Test->{Name}) - with True",
        );

        # get the value with ValueGet()
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $Test->{DynamicFieldConfig},
            ObjectID           => $Test->{ObjectID},
        );

        # sanity check
        $Self->True(
            $Value,
            "ValueGet() after ValueSet() - (Test $Test->{Name}) - with True",
        );

        # compare data
        for my $ValueKey ( keys %{ $Test->{Value} } ) {
            $Self->Is(
                $Value->{$ValueKey},
                $Test->{Value}->{$ValueKey},
                "ValueGet() after ValueSet() - (Test $Test->{Name}) - Key $ValueKey",
            );
        }
    }
}

# specific tests for ValueGet()
@Tests = (
    {
        Name               => 'Wrong FieldID',
        DynamicFieldConfig => {
            ID         => -1,
            ObjectType => 'Ticket',
        },
        ObjectID => $TicketID,
        UserID   => 1,
    },
    {
        Name               => 'Wrong ObjectType',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'InvalidObject',
        },
        ObjectID => $TicketID,
        UserID   => 1,
    },
    {
        Name               => 'Wrong ObjectID',
        DynamicFieldConfig => {
            ID         => $FieldID,
            ObjectType => 'Ticket',
        },
        ObjectID => -1,
        UserID   => 1,
    },
);

for my $Test (@Tests) {

    # try to get the value with ValueGet()
    my $Value = $BackendObject->ValueGet(
        DynamicFieldConfig => $Test->{DynamicFieldConfig},
        ObjectID           => $Test->{ObjectID},
    );

    $Self->False(
        $Value->{ID},
        "ValueGet() - Test ($Test->{Name}) - with False",
    );

}

# delete the dynamic field
my $FieldDelete = $DynamicFieldObject->DynamicFieldDelete(
    ID     => $FieldID,
    UserID => 1,
);

# sanity check
$Self->True(
    $FieldDelete,
    "DynamicFieldDelete() successful for Field ID $FieldID",
);

# delete the ticket
my $TicketDelete = $TicketObject->TicketDelete(
    TicketID => $TicketID,
    UserID   => 1,
);

# sanity check
$Self->True(
    $TicketDelete,
    "TicketDelete() successful for Ticket ID $TicketID",
);

1;
