% spots.m
% [lid, 2011/18/12]
% integrate spot price and project the total cost for a year
% 
clear
% ec2-describe-spot-price-history --start-time 2010-12-18T00:00:00+0000 --instance-type t1.micro --product-description Linux/UNIX --end-time 2011-12-18T00:00:00+0000 --availability-zone us-east-1b 

apiCmd = 'source ~/.bash_profile; ec2-describe-spot-price-history';

% Linux/UNIX | SUSE Linux | Windows | Linux/UNIX (Amazon VPC) | SUSE Linux (Amazon VPC) | Windows (Amazon VPC)
OS = 'Linux/UNIX';

% availability zones
zone = 'us-east-1f';
region = 'us-east-1';

% m1.small | m1.large | m1.xlarge | c1.medium | c1.xlarge | m2.xlarge | m2.2xlarge | m2.4xlarge | t1.micro
type = 't1.micro';     

file = 'spots_data.tmp';

cmdToRun = [apiCmd  ' --start-time 2000-12-18T00:00:00+0000 -t ' type ' -a ' zone ' -d ' OS ' --region ' region ' > ' file];
disp(cmdToRun);
fprintf('Fetching data... ');
[status,result] = system(cmdToRun);
if (status ~= 0)
    error('Error fetching data: %s', result);
end
fprintf('done.\n');

fid = fopen(file,'r');

if (fid == -1)
    error('Could not open file!');
end

formatStr = '%s%n%s%s%s%s'; % fields are whitespace delimited
a = textscan(fid,formatStr);
fclose(fid);

prices = a{2};
times = a{3};
numEntries = length(prices);
fixedT = zeros(1,numEntries);   % preallocated parsed datenum vector
regex = '(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})T(?<hour>\d{2}):(?<min>\d{2}):(?<sec>\d{2})';
parsed = regexp(times,regex,'names');   % parse time stamp
for i = 1:numEntries
    fixedT(i) = datenum(str2num(parsed{i}.year),str2num(parsed{i}.month),...
        str2num(parsed{i}.day),str2num(parsed{i}.hour),str2num(parsed{i}.min),...
        str2num(parsed{i}.sec)); %#ok<*ST2NM>
end
intervalDays = fixedT(1:numEntries-1) - fixedT(2:numEntries); % each time interval, in days
intervalHours = intervalDays * 24;  % convert to hours
pricesFixed = prices(2:numEntries)';
cost = pricesFixed .* intervalHours;
totalCost = sum(cost);
hoursInYear = 365*24;
costPerYear = hoursInYear/sum(intervalHours)*totalCost;

% generate plots
xlabels = fixedT - max(fixedT);
clf;
[AX,H1,H2] = plotyy(xlabels(1:numEntries-1),sum(cost)-cumsum(cost),xlabels(1:numEntries-1),cost);
hold on;
set(H2,'LineStyle','x')
set(get(AX(1),'Ylabel'),'String','Cumulative cost ($)') 
set(get(AX(2),'Ylabel'),'String','Spot price ($)') 
title([type ', ' zone ', ' OS ', $' num2str(costPerYear,'%10.2f') '/yr']);
xlabel('Days from present');