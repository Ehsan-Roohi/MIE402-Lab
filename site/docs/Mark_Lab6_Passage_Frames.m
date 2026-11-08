% LAB 6 - MARK CONSECUTIVE VANE CROSSINGS IN THE ORIGINAL VIDEO
% Right/Left: advance/back one step. Up/Down: increase/decrease step.
% Space: mark current frame. Backspace: remove last mark. Q: save and quit.
clear; clc;
[fn,folder]=uigetfile({'*.mp4;*.avi;*.mov','Video files';'*.*','All files'},'Select ORIGINAL radiometer video');
if isequal(fn,0), return; end
v=VideoReader(fullfile(folder,fn));
% File frame rate is used ONLY for navigation, never physical time.
nmax=max(1,floor(v.Duration*v.FrameRate));
idx=1; step=1; frames=[];
fig=figure('Color','w','Name','Lab 6 passage marker','NumberTitle','off');
ax=axes(fig); h=image(ax,read(v,idx)); axis(ax,'image'); axis(ax,'off');
disp('Choose a fixed reference line in the image; record the same event and direction each time.');
while isgraphics(fig)
 title(ax,sprintf('Original frame %d | step %d | marks %d\nArrows navigate; SPACE mark; BACKSPACE undo; Q save',idx-1,step,numel(frames)));
 keypress=waitforbuttonpress;
 if ~isgraphics(fig), break; end
 if ~keypress, continue; end
 key=get(fig,'CurrentKey');
 switch key
  case 'rightarrow', idx=min(nmax,idx+step);
  case 'leftarrow', idx=max(1,idx-step);
  case 'uparrow', step=min(1000,step*10);
  case 'downarrow', step=max(1,round(step/10));
  case 'space'
   if isempty(frames)||idx-1>frames(end)
    frames(end+1,1)=idx-1; %#ok<SAGROW>
    fprintf('Marked frame %d\n',idx-1);
   else
    disp('Marks must increase. Undo later marks before replacing an earlier crossing.');
   end
  case 'backspace'
   if ~isempty(frames), frames(end)=[]; end
  case 'q', break;
 end
 try
  set(h,'CData',read(v,idx));
 catch err
  disp(err.message); idx=max(1,idx-step); nmax=idx;
  set(h,'CData',read(v,idx));
 end
end
if isgraphics(fig), close(fig); end
if isempty(frames), disp('No crossings marked. Nothing saved.'); return; end
out=fullfile(folder,[erase(fn,{'.mp4','.avi','.mov'}) '_passages.csv']);
writetable(table(frames,'VariableNames',{'frame'}),out);
fprintf('Saved %d passage frames to %s\nNow run Run_Lab6_Radiometer.m.\n',numel(frames),out);
