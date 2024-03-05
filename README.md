# NextGen Missing Accounts
Generate accounts in NextGen EPM where they do not currently exist.

## Issue #1
Our version of NextGen (5.9) has a bug where encounters where the guarantor does not have an account will not show in the patient chart window in EPM.

We were provided an initial fix by GBS that used a cursor to insert accounts for missing ones.

## Issue #2
We have an employer with 100k+ encounters. The autoflow and loading a patient with this employer as a guarantor are being bogged down loading and aggregating account balances. We were advised to start creating a new employer (and account) each year to limit the number of encounters.

We have other employers nearing or beginning to display similar threshold issues.

We would like not to have to manage the employers yearly.

## Solution

Deploy an SP that will generate an account for missing ones for guarantors to fix the missing encounters. Modify it with a parameter to also be used for these employer encounters.

Flip guarantors for the overloaded employer (and possibly future employers) to the person when the balance is 0 and the encounter is in a History status.

## Development / Testing
A cursor is too slow for the amount of encounters the employer portion we were attempting to deploy. We rafactored it to use inserts from a temp table instead.

Added a parameter to direct it at an employer (we can expand this to other employers in the future.)

Added a parameter to limit it for testing / in case we need to run it in batches for performance issues later.

### Analysis
* Demo
    * Total accounts: 4,290,951
    * Missing employer accounts: (158,670)
        * Minors (_under 18 today_): 213
    * No account for guarantor: 143 accounts
* Prod
    * Total accounts: 4,372,578
    * Missing employer accounts: (196,155)
        * Created daily: average last 100 days: 16
    * No account but a guarantor: 140
        * Created daily: average last 10 days: 1

## Usage
The Stored Procuder is called csm_missingacct. It takes 3 parameters: 
* read_or_load (bit)
    * defaults to 0 -- reporting on what will be created
    * 1 inserts accounts and updates practice correlated last_generated  value on system_counter table
* accounttype (varchar(30))
    * currently accepts 2
        * 'missing' -- default
        * 'escreen'
* limitInt (integer)
    * Limits the amount of rows to be processed (defaults to 100)
        * Based on analysis this default limit should be more than enough but we can override it if necessary


