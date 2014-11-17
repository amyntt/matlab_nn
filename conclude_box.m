function [boxes_memory, boxes_para, box_history, box_history_index] = ...
    conclude_box(boxes_para, boxes_memory, pe, box_history, box_history_index, e, no_nn)

% boxes_para = zeros(max_box,11); % mean and std, 7:threshold, 8:n,
% 9:status: 0 unused 1 in progress 10: current 11: count



box_id = pe(3);
box_mem = boxes_memory{box_id,1};
% just the density?

[no_mem, ~] = size(box_mem);

current = 0;

old_mu = (boxes_para(box_id,1:3))';
old_mu(3) = 0;
box_mem(:,3) = box_mem(:,3) - mean(box_mem(:,3));
sig = zeros(3,3);
for i = 1:3
    sig(i,i) = boxes_para(box_id,3+1) ^2;
end

furthest_pt = old_mu + (3*boxes_para(box_id,4:6))';
max_dist = sqrt((furthest_pt-old_mu)' * sig * (furthest_pt-old_mu));
for m = 1:no_mem
   md = sqrt((box_mem(m,:)'-old_mu)' * sig * (box_mem(m,:)'-old_mu));
   % md 0 sould = 1, what is the max?
   md = min(md, max_dist);
   current = current + (1-(md/max_dist));
end

current = current / no_mem;

if current > boxes_para(box_id,7) && no_mem >= no_nn
    
    %%% it fires
    boxes_para(box_id,11) = boxes_para(box_id,11) + 1;
    box_history_index = box_history_index + 1;
    box_history(box_history_index,:) = [box_id, pe(1)];
    

    old_C = zeros(3,3);
    for i = 1:3
        old_C(i,i) = boxes_para(box_id, i+3) ^2;
    end
%     if e > 50000
%         figure
%         plot_gaussian_ellipsoid_contouronly(old_mu, old_C, 1, 4, [1 0 0])
%         fprintf('old_mu\n');
%         old_mu
%         fprintf('old_C\n');
%         old_C
%         fprintf('old_no\n');
%         boxes_para(box_id,8)
%     end
    
    %%% learnt
    
    n = boxes_para(box_id,8);
    m = no_mem;    
    mem_mu = mean(box_mem);
    box_mem(:,3) = box_mem(:,3) - mem_mu(3);
    mem_mu = mean(box_mem);
    mem_std = std(box_mem);
    
    mem_C = zeros(3,3);
    for i = 1:3
        mem_C(i,i) = mem_std(i) ^2;
    end

     
%      if box_id == 1,
%          sbi = sbi + 1;
%          specific_box_history{sbi,1} = boxes_para(1,:);
%          mem_para = zeros(1,11);
%          mem_para(1:3) = mem_mu(:);
%          mem_para(4:6) = mem_std(:);
%          mem_para(11) = m;
%          specific_box_history{sbi,2} = mem_para;
%      end
     
     
     
     
    
    new_mu = zeros(1,3);
    new_mu(1) = (n*old_mu(1) + m*(mem_mu(1))) / (m+n);
    new_mu(2) = (n*old_mu(2) + m*(mem_mu(2))) / (m+n);
    
    new_sig = zeros(1,3);
    
    for i = 1:3        
        part1 = n*(old_C(i,i) + old_mu(i)^2);
        part2 = m*(mem_C(i,i) + mem_mu(i)^2);        
        new_sig(i) = (part1 + part2)/(m+n) - new_mu(i)^2;
    end
    
%     new_C = zeros(3,3);
%     for i = 1:3
%         new_C(i,i) = new_sig(i);
%     end
%      if e > 50000
%         hold on
%         plot_gaussian_ellipsoid_contouronly(new_mu, new_C, 1, 4, [0 0 1])
%         fprintf('new_mu\n');
%         new_mu
%         fprintf('new_C\n');
%         new_C
%      end
    
     
     
     
    boxes_para(box_id,1:2) = new_mu(1:2);
    boxes_para(box_id,4:6) = sqrt(new_sig);
    boxes_para(box_id,8) = m+n;
    
%     if box_id == 1,         
%          specific_box_history{sbi,3} = boxes_para(1,:);
%     end
end

boxes_memory{box_id,1} = [];
boxes_para(box_id,9) = 0;
boxes_para(box_id,10) = 0;    